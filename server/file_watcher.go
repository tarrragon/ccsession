package main

import (
	"bufio"
	"context"
	"log/slog"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
)

// File watcher log messages
const (
	LogWatcherStarting       = "file watcher starting"
	LogWatcherStopped        = "file watcher stopped"
	LogWatcherScanExisting   = "scanning existing JSONL files"
	LogWatcherFileAdded      = "JSONL file added"
	LogWatcherFileModified   = "JSONL file modified"
	LogWatcherFileRemoved    = "JSONL file removed"
	LogWatcherReadError      = "error reading JSONL file"
	LogWatcherParseError     = "error parsing JSONL line"
	LogWatcherWatchDirError  = "error watching directory"
	LogWatcherScanError      = "error scanning projects directory"
	LogWatcherPermissionWarn = "permission denied, skipping file"
	LogWatcherFsnotifyError  = "fsnotify error"
	LogWatcherNewDir         = "watching new project directory"
	LogWatcherEventDropped   = "event channel full, dropping event"
)

// FileWatcher monitors ~/.claude/projects/ for JSONL file changes
// and emits parsed SessionEvents through a channel.
type FileWatcher struct {
	claudeHome string
	readers    map[string]*SessionFileReader
	eventCh    chan SessionEvent
	watcher    *fsnotify.Watcher
	mu         sync.RWMutex
	logger     *slog.Logger
}

// SessionFileReader tracks read progress for a single JSONL file.
type SessionFileReader struct {
	filePath    string
	offset      int64
	sessionID   string
	projectPath string
}

// NewFileWatcher creates a FileWatcher that monitors claudeHome/projects/
// for JSONL file changes and sends parsed events to eventCh.
func NewFileWatcher(claudeHome string, eventCh chan SessionEvent) *FileWatcher {
	return &FileWatcher{
		claudeHome: claudeHome,
		readers:    make(map[string]*SessionFileReader),
		eventCh:    eventCh,
		logger:     slog.Default(),
	}
}

// Events returns a read-only channel of parsed session events.
func (fw *FileWatcher) Events() <-chan SessionEvent {
	return fw.eventCh
}

// Start begins watching for JSONL file changes. It scans existing files,
// then monitors for create/write/remove events. Blocks until ctx is cancelled.
func (fw *FileWatcher) Start(ctx context.Context) error {
	fw.logger.Info(LogWatcherStarting,
		"layer", "file_watcher",
		"claudeHome", fw.claudeHome)

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return err
	}
	defer watcher.Close()

	fw.watcher = watcher

	projectsDir := filepath.Join(fw.claudeHome, ProjectsDirName)
	if err := fw.scanExistingFiles(projectsDir, watcher); err != nil {
		fw.logger.Warn(LogWatcherScanError,
			"layer", "file_watcher",
			"error", err.Error())
	}

	// Watch the projects directory itself for new subdirectories
	if err := watcher.Add(projectsDir); err != nil {
		fw.logger.Warn(LogWatcherWatchDirError,
			"layer", "file_watcher",
			"path", projectsDir,
			"error", err.Error())
	}

	fw.logger.Info(LogWatcherScanExisting,
		"layer", "file_watcher",
		"fileCount", fw.readerCount())

	for {
		select {
		case <-ctx.Done():
			fw.logger.Info(LogWatcherStopped, "layer", "file_watcher")
			return nil

		case event, ok := <-watcher.Events:
			if !ok {
				return nil
			}
			fw.handleFsEvent(event, watcher)

		case err, ok := <-watcher.Errors:
			if !ok {
				return nil
			}
			fw.logger.Warn(LogWatcherFsnotifyError,
				"layer", "file_watcher",
				"error", err.Error())
		}
	}
}

// scanExistingFiles walks the projects directory, adds watchers for each
// project subdirectory, and reads any existing JSONL files.
func (fw *FileWatcher) scanExistingFiles(projectsDir string, watcher *fsnotify.Watcher) error {
	entries, err := os.ReadDir(projectsDir)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		subDir := filepath.Join(projectsDir, entry.Name())
		if err := watcher.Add(subDir); err != nil {
			fw.logger.Warn(LogWatcherWatchDirError,
				"layer", "file_watcher",
				"path", subDir,
				"error", err.Error())
			continue
		}

		files, err := os.ReadDir(subDir)
		if err != nil {
			fw.logger.Warn(LogWatcherScanError,
				"layer", "file_watcher",
				"path", subDir,
				"error", err.Error())
			continue
		}
		for _, f := range files {
			if !f.IsDir() && strings.HasSuffix(f.Name(), JSONLExtension) {
				fw.addFileSeekEnd(filepath.Join(subDir, f.Name()))
			}
		}
	}
	return nil
}

// handleFsEvent processes a single fsnotify event.
func (fw *FileWatcher) handleFsEvent(event fsnotify.Event, watcher *fsnotify.Watcher) {
	path := event.Name

	if event.Has(fsnotify.Create) {
		info, err := os.Stat(path)
		if err != nil {
			return
		}
		if info.IsDir() {
			// New project subdirectory: start watching it
			if err := watcher.Add(path); err != nil {
				fw.logger.Warn(LogWatcherWatchDirError,
					"layer", "file_watcher",
					"path", path,
					"error", err.Error())
			} else {
				fw.logger.Info(LogWatcherNewDir,
					"layer", "file_watcher",
					"path", path)
			}
			return
		}
		if strings.HasSuffix(path, JSONLExtension) {
			fw.logger.Info(LogWatcherFileAdded,
				"layer", "file_watcher",
				"path", path)
			fw.addFile(path)
		}
	}

	if event.Has(fsnotify.Write) {
		if strings.HasSuffix(path, JSONLExtension) {
			fw.logger.Debug(LogWatcherFileModified,
				"layer", "file_watcher",
				"path", path)
			fw.readNewLines(path)
		}
	}

	if event.Has(fsnotify.Remove) || event.Has(fsnotify.Rename) {
		if strings.HasSuffix(path, JSONLExtension) {
			fw.logger.Info(LogWatcherFileRemoved,
				"layer", "file_watcher",
				"path", path)
			fw.removeFile(path)
		}
	}
}

// addFile registers a new JSONL file and reads its existing content.
// On macOS (kqueue), a CREATE event may fire before the file content is
// flushed, so we retry once after a short delay if no lines are read.
func (fw *FileWatcher) addFile(path string) {
	sessionID, projectPath := extractSessionInfo(path)

	reader := &SessionFileReader{
		filePath:    path,
		offset:      0,
		sessionID:   sessionID,
		projectPath: projectPath,
	}

	fw.mu.Lock()
	fw.readers[path] = reader
	fw.mu.Unlock()

	// Watch individual file for WRITE events (required on macOS kqueue)
	fw.watchFile(path)

	fw.readNewLinesForReader(reader)

	// On macOS kqueue, CREATE may fire before content is written.
	// If we read nothing, retry after a short delay to catch the content.
	if reader.offset == 0 {
		time.AfterFunc(AddFileRetryDelay, func() {
			fw.readNewLinesForReader(reader)
		})
	}
}

// addFileSeekEnd registers a JSONL file and seeks to the end without reading
// history. Used during initial scan to avoid flooding eventCh with old events.
func (fw *FileWatcher) addFileSeekEnd(path string) {
	sessionID, projectPath := extractSessionInfo(path)

	// Determine file size to set offset at EOF
	info, err := os.Stat(path)
	if err != nil {
		fw.logger.Warn(LogWatcherReadError,
			"layer", "file_watcher",
			"path", path,
			"error", err.Error())
		return
	}

	reader := &SessionFileReader{
		filePath:    path,
		offset:      info.Size(),
		sessionID:   sessionID,
		projectPath: projectPath,
	}

	fw.mu.Lock()
	fw.readers[path] = reader
	fw.mu.Unlock()

	// Watch individual file for WRITE events (required on macOS kqueue)
	fw.watchFile(path)
}

// watchFile adds an individual file to the fsnotify watcher.
// On macOS kqueue, directory watches don't emit WRITE events for files,
// so each JSONL file must be watched individually.
func (fw *FileWatcher) watchFile(path string) {
	if fw.watcher == nil {
		return
	}
	if err := fw.watcher.Add(path); err != nil {
		fw.logger.Warn(LogWatcherWatchDirError,
			"layer", "file_watcher",
			"path", path,
			"error", err.Error())
	}
}

// readNewLines reads newly appended lines from a known JSONL file.
func (fw *FileWatcher) readNewLines(path string) {
	fw.mu.RLock()
	reader, ok := fw.readers[path]
	fw.mu.RUnlock()

	if !ok {
		// File not yet tracked; treat as a new file
		fw.addFile(path)
		return
	}

	fw.readNewLinesForReader(reader)
}

// readNewLinesForReader reads from the reader's current offset,
// parses each line, and sends events to the channel.
func (fw *FileWatcher) readNewLinesForReader(r *SessionFileReader) {
	f, err := os.Open(r.filePath)
	if err != nil {
		if os.IsPermission(err) {
			fw.logger.Warn(LogWatcherPermissionWarn,
				"layer", "file_watcher",
				"path", r.filePath,
				"error", err.Error())
			return
		}
		fw.logger.Warn(LogWatcherReadError,
			"layer", "file_watcher",
			"path", r.filePath,
			"error", err.Error())
		return
	}
	defer f.Close()

	if _, err := f.Seek(r.offset, 0); err != nil {
		fw.logger.Warn(LogWatcherReadError,
			"layer", "file_watcher",
			"path", r.filePath,
			"error", err.Error())
		return
	}

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Bytes()
		if len(line) == 0 {
			continue
		}

		events, err := ParseLine(line, r.sessionID, r.projectPath)
		if err != nil {
			fw.logger.Warn(LogWatcherParseError,
				"layer", "file_watcher",
				"sessionID", r.sessionID,
				"error", err.Error())
			continue
		}

		for _, evt := range events {
			select {
			case fw.eventCh <- evt:
				// sent successfully
			default:
				fw.logger.Warn(LogWatcherEventDropped,
					"layer", "file_watcher",
					"sessionID", r.sessionID,
					"eventType", evt.Type)
			}
		}
	}

	// Update offset to current file position
	pos, err := f.Seek(0, 1)
	if err == nil {
		r.offset = pos
	}
}

// removeFile emits a session_completed event and removes the reader.
func (fw *FileWatcher) removeFile(path string) {
	fw.mu.Lock()
	reader, ok := fw.readers[path]
	if ok {
		delete(fw.readers, path)
	}
	fw.mu.Unlock()

	// Remove individual file watch (ignore error if already removed by OS)
	if fw.watcher != nil {
		_ = fw.watcher.Remove(path)
	}

	if ok {
		evt := SessionEvent{
			SessionID:     reader.sessionID,
			ProjectPath:   reader.projectPath,
			Type:          EventTypeSessionCompleted,
			Timestamp:     time.Now(),
			ContentIndex:  ContentIndexNone,
			IsLastContent: true,
		}
		select {
		case fw.eventCh <- evt:
			// sent successfully
		default:
			fw.logger.Warn(LogWatcherEventDropped,
				"layer", "file_watcher",
				"sessionID", reader.sessionID,
				"eventType", evt.Type)
		}
	}
}

// readerCount returns the number of tracked JSONL files.
func (fw *FileWatcher) readerCount() int {
	fw.mu.RLock()
	defer fw.mu.RUnlock()
	return len(fw.readers)
}

// extractSessionInfo derives sessionID and projectPath from a JSONL file path.
// Path format: {claudeHome}/projects/{encoded_project_path}/{session_id}.jsonl
func extractSessionInfo(path string) (sessionID, projectPath string) {
	base := filepath.Base(path)
	sessionID = strings.TrimSuffix(base, JSONLExtension)

	dir := filepath.Dir(path)
	encodedProject := filepath.Base(dir)
	decoded, err := url.PathUnescape(encodedProject)
	if err != nil {
		projectPath = encodedProject
	} else {
		projectPath = decoded
	}
	return sessionID, projectPath
}
