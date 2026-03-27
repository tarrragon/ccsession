package main

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// Test helper: build a minimal valid JSONL line for a user message.
func makeUserJSONL(t *testing.T, uuid, text string) []byte {
	t.Helper()
	record := map[string]any{
		"uuid":      uuid,
		"type":      "human",
		"timestamp": time.Now().UTC().Format(time.RFC3339Nano),
		"message": map[string]any{
			"role":    "user",
			"content": text,
		},
	}
	data, err := json.Marshal(record)
	if err != nil {
		t.Fatalf("failed to marshal test JSONL: %v", err)
	}
	return data
}

// Test helper: build a minimal valid JSONL line for an assistant message.
func makeAssistantJSONL(t *testing.T, uuid, text string) []byte {
	t.Helper()
	record := map[string]any{
		"uuid":      uuid,
		"type":      "ai",
		"timestamp": time.Now().UTC().Format(time.RFC3339Nano),
		"message": map[string]any{
			"role":    "assistant",
			"content": text,
		},
	}
	data, err := json.Marshal(record)
	if err != nil {
		t.Fatalf("failed to marshal test JSONL: %v", err)
	}
	return data
}

// setupTestClaudeHome creates a temporary directory structure mimicking
// ~/.claude/projects/{encoded_path}/{session}.jsonl
func setupTestClaudeHome(t *testing.T) (claudeHome string, projectDir string) {
	t.Helper()
	claudeHome = t.TempDir()
	projectDir = filepath.Join(claudeHome, ProjectsDirName, "test-project")
	if err := os.MkdirAll(projectDir, 0o755); err != nil {
		t.Fatalf("failed to create project dir: %v", err)
	}
	return claudeHome, projectDir
}

// drainEvents collects events from the channel until timeout or count reached.
func drainEvents(ch <-chan SessionEvent, want int, timeout time.Duration) []SessionEvent {
	var events []SessionEvent
	deadline := time.After(timeout)
	for len(events) < want {
		select {
		case evt := <-ch:
			events = append(events, evt)
		case <-deadline:
			return events
		}
	}
	return events
}

func TestNewFileWatcher(t *testing.T) {
	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher("/tmp/fake-claude", ch)

	if fw.claudeHome != "/tmp/fake-claude" {
		t.Errorf("claudeHome = %q, want %q", fw.claudeHome, "/tmp/fake-claude")
	}
	if fw.readers == nil {
		t.Error("readers map should be initialized")
	}
	if fw.eventCh == nil {
		t.Error("eventCh should not be nil")
	}
	if fw.logger == nil {
		t.Error("logger should not be nil")
	}
}

func TestFileWatcherEventsChannel(t *testing.T) {
	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher("/tmp/fake", ch)

	readCh := fw.Events()
	if readCh == nil {
		t.Fatal("Events() returned nil")
	}

	// Verify it's the same underlying channel
	ch <- SessionEvent{SessionID: "test-123"}
	evt := <-readCh
	if evt.SessionID != "test-123" {
		t.Errorf("SessionID = %q, want %q", evt.SessionID, "test-123")
	}
}

func TestFileWatcherScanExisting(t *testing.T) {
	claudeHome, projectDir := setupTestClaudeHome(t)

	// Write a JSONL file before starting the watcher
	jsonlPath := filepath.Join(projectDir, "session-001.jsonl")
	line := makeUserJSONL(t, "msg-1", "hello world")
	if err := os.WriteFile(jsonlPath, append(line, '\n'), 0o644); err != nil {
		t.Fatalf("failed to write JSONL: %v", err)
	}

	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher(claudeHome, ch)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		if err := fw.Start(ctx); err != nil {
			t.Errorf("Start returned error: %v", err)
		}
	}()

	// Initial scan should skip history (seek to EOF), so no events expected
	events := drainEvents(ch, 1, 1*time.Second)
	if len(events) != 0 {
		t.Errorf("expected 0 events from initial scan (history skipped), got %d", len(events))
	}

	// Verify the reader was registered
	fw.mu.RLock()
	reader, ok := fw.readers[jsonlPath]
	fw.mu.RUnlock()
	if !ok {
		t.Fatal("expected reader to be registered for existing file")
	}
	if reader.sessionID != "session-001" {
		t.Errorf("SessionID = %q, want %q", reader.sessionID, "session-001")
	}
	if reader.projectPath != "test-project" {
		t.Errorf("ProjectPath = %q, want %q", reader.projectPath, "test-project")
	}
	// Offset should be at EOF (file size)
	info, err := os.Stat(jsonlPath)
	if err != nil {
		t.Fatalf("failed to stat file: %v", err)
	}
	if reader.offset != info.Size() {
		t.Errorf("offset = %d, want %d (EOF)", reader.offset, info.Size())
	}
}

func TestFileWatcherNewFile(t *testing.T) {
	claudeHome, projectDir := setupTestClaudeHome(t)

	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher(claudeHome, ch)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		if err := fw.Start(ctx); err != nil {
			t.Errorf("Start returned error: %v", err)
		}
	}()

	// Give the watcher time to start
	time.Sleep(200 * time.Millisecond)

	// Create a new JSONL file after watcher is running
	jsonlPath := filepath.Join(projectDir, "session-new.jsonl")
	line := makeAssistantJSONL(t, "msg-a1", "I can help with that")
	if err := os.WriteFile(jsonlPath, append(line, '\n'), 0o644); err != nil {
		t.Fatalf("failed to write JSONL: %v", err)
	}

	events := drainEvents(ch, 1, 3*time.Second)
	if len(events) < 1 {
		t.Fatal("expected at least 1 event from new file, got 0")
	}

	if events[0].SessionID != "session-new" {
		t.Errorf("SessionID = %q, want %q", events[0].SessionID, "session-new")
	}
	if events[0].Type != EventTypeAssistant {
		t.Errorf("Type = %q, want %q", events[0].Type, EventTypeAssistant)
	}
}

func TestFileWatcherAppend(t *testing.T) {
	claudeHome, projectDir := setupTestClaudeHome(t)

	// Write initial content
	jsonlPath := filepath.Join(projectDir, "session-append.jsonl")
	line1 := makeUserJSONL(t, "msg-1", "first message")
	if err := os.WriteFile(jsonlPath, append(line1, '\n'), 0o644); err != nil {
		t.Fatalf("failed to write JSONL: %v", err)
	}

	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher(claudeHome, ch)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		if err := fw.Start(ctx); err != nil {
			t.Errorf("Start returned error: %v", err)
		}
	}()

	// Initial scan skips history (seeks to EOF), so no events to drain.
	// Give watcher time to start.
	time.Sleep(200 * time.Millisecond)

	// Append a new line to the file
	line2 := makeAssistantJSONL(t, "msg-2", "second message")
	f, err := os.OpenFile(jsonlPath, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		t.Fatalf("failed to open file for append: %v", err)
	}
	if _, err := f.Write(append(line2, '\n')); err != nil {
		f.Close()
		t.Fatalf("failed to append: %v", err)
	}
	f.Close()

	// Should only get the second event (offset-based reading)
	events := drainEvents(ch, 1, 3*time.Second)
	if len(events) < 1 {
		t.Fatal("expected 1 event from appended line, got 0")
	}

	if events[0].Content.Text != "second message" {
		t.Errorf("Content.Text = %q, want %q", events[0].Content.Text, "second message")
	}
	if events[0].Type != EventTypeAssistant {
		t.Errorf("Type = %q, want %q", events[0].Type, EventTypeAssistant)
	}
}

func TestFileWatcherRemove(t *testing.T) {
	claudeHome, projectDir := setupTestClaudeHome(t)

	// Write a file before starting
	jsonlPath := filepath.Join(projectDir, "session-remove.jsonl")
	line := makeUserJSONL(t, "msg-r1", "will be removed")
	if err := os.WriteFile(jsonlPath, append(line, '\n'), 0o644); err != nil {
		t.Fatalf("failed to write JSONL: %v", err)
	}

	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher(claudeHome, ch)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		if err := fw.Start(ctx); err != nil {
			t.Errorf("Start returned error: %v", err)
		}
	}()

	// Initial scan skips history, give watcher time to start
	time.Sleep(200 * time.Millisecond)

	// Remove the file
	if err := os.Remove(jsonlPath); err != nil {
		t.Fatalf("failed to remove file: %v", err)
	}

	events := drainEvents(ch, 1, 3*time.Second)
	if len(events) < 1 {
		t.Fatal("expected session_completed event after remove, got 0")
	}

	evt := events[0]
	if evt.Type != EventTypeSessionCompleted {
		t.Errorf("Type = %q, want %q", evt.Type, EventTypeSessionCompleted)
	}
	if evt.SessionID != "session-remove" {
		t.Errorf("SessionID = %q, want %q", evt.SessionID, "session-remove")
	}
}

func TestFileWatcherPermissionError(t *testing.T) {
	// Skip on CI or if running as root (permissions won't work)
	if os.Getuid() == 0 {
		t.Skip("skipping permission test as root")
	}

	claudeHome, projectDir := setupTestClaudeHome(t)

	// Write a file with no read permission
	jsonlPath := filepath.Join(projectDir, "session-noperm.jsonl")
	line := makeUserJSONL(t, "msg-p1", "secret")
	if err := os.WriteFile(jsonlPath, append(line, '\n'), 0o000); err != nil {
		t.Fatalf("failed to write JSONL: %v", err)
	}
	// Ensure cleanup can remove the file
	t.Cleanup(func() {
		os.Chmod(jsonlPath, 0o644)
	})

	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher(claudeHome, ch)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		if err := fw.Start(ctx); err != nil {
			t.Errorf("Start returned error: %v", err)
		}
	}()

	// Should not receive any events (permission denied is logged as WARN)
	events := drainEvents(ch, 1, 1*time.Second)
	if len(events) != 0 {
		t.Errorf("expected 0 events for permission-denied file, got %d", len(events))
	}
}

func TestFileWatcherContextCancel(t *testing.T) {
	claudeHome, _ := setupTestClaudeHome(t)

	ch := make(chan SessionEvent, DefaultEventChannelSize)
	fw := NewFileWatcher(claudeHome, ch)

	ctx, cancel := context.WithCancel(context.Background())

	done := make(chan error, 1)
	go func() {
		done <- fw.Start(ctx)
	}()

	// Give watcher time to start, then cancel
	time.Sleep(100 * time.Millisecond)
	cancel()

	select {
	case err := <-done:
		if err != nil {
			t.Errorf("Start returned error after cancel: %v", err)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("watcher did not stop within 3 seconds after context cancel")
	}
}

func TestExtractSessionInfo(t *testing.T) {
	tests := []struct {
		name            string
		path            string
		wantSessionID   string
		wantProjectPath string
	}{
		{
			name:            "simple project path",
			path:            "/home/user/.claude/projects/my-project/abc123.jsonl",
			wantSessionID:   "abc123",
			wantProjectPath: "my-project",
		},
		{
			name:            "URL-encoded project path",
			path:            "/home/user/.claude/projects/%2FUsers%2Feric%2Fcode/sess-456.jsonl",
			wantSessionID:   "sess-456",
			wantProjectPath: "/Users/eric/code",
		},
		{
			name:            "UUID session ID",
			path:            "/tmp/claude/projects/demo/550e8400-e29b-41d4-a716-446655440000.jsonl",
			wantSessionID:   "550e8400-e29b-41d4-a716-446655440000",
			wantProjectPath: "demo",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			gotSID, gotPP := extractSessionInfo(tc.path)
			if gotSID != tc.wantSessionID {
				t.Errorf("sessionID = %q, want %q", gotSID, tc.wantSessionID)
			}
			if gotPP != tc.wantProjectPath {
				t.Errorf("projectPath = %q, want %q", gotPP, tc.wantProjectPath)
			}
		})
	}
}
