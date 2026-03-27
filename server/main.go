package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/anthropics/ccsession-monitor/messages"
)

func main() {
	// 結構化日誌初始化
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))
	slog.SetDefault(logger)

	// Claude Code 版本偵測（決定 HTTP Hooks 是否啟用）
	versionConfig := DetectClaudeVersion(logger, &defaultCommandRunner{})

	// claudeHome 偵測
	claudeHome := resolveClaudeHome()

	// 連接埠設定
	port := DefaultPort
	if p := os.Getenv("PORT"); p != "" {
		port = p
	}

	// 建立 channels
	sessionEvCh := make(chan SessionEvent, SessionEventChBufferSize)
	hookEvCh := make(chan HookEvent, HookEventChBufferSize)
	dispatchCh := make(chan DispatchedEvent, DispatchChBufferSize)

	// 初始化元件
	timeProvider := time.Now
	registry := NewSessionRegistry(timeProvider)
	watcher := NewFileWatcher(claudeHome, sessionEvCh, registry)
	dispatcher := NewEventDispatcher(registry, sessionEvCh, hookEvCh, dispatchCh, timeProvider)
	wsServer := NewWebSocketServer(registry, dispatchCh, timeProvider)

	// Context 管理（graceful shutdown）
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 啟動背景 goroutines
	go runFileWatcher(ctx, watcher, logger)
	go dispatcher.Run(ctx)
	go wsServer.Run(ctx)

	// 註冊 HTTP endpoints
	mux := http.NewServeMux()
	mux.HandleFunc("/health", handleHealth)
	mux.HandleFunc("/ws", wsServer.HandleWS)
	registerHooksEndpoint(mux, versionConfig, hookEvCh, logger)

	// 監聽 shutdown 信號
	addr := "localhost:" + port
	server := &http.Server{Addr: addr, Handler: mux}

	go waitForShutdown(cancel, logger)

	logger.Info(messages.LogServerStarting, "layer", "main", "addr", addr)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Error("server failed", "layer", "main", "error", err)
		os.Exit(1)
	}
}

// resolveClaudeHome 決定 Claude 設定目錄路徑。
// 優先使用 CLAUDE_HOME 環境變數，否則使用 $HOME/.claude。
func resolveClaudeHome() string {
	if ch := os.Getenv("CLAUDE_HOME"); ch != "" {
		return ch
	}
	home, err := os.UserHomeDir()
	if err != nil {
		slog.Error("cannot determine home directory", "layer", "main", "error", err)
		os.Exit(1)
	}
	return filepath.Join(home, DefaultClaudeHomeSubdir)
}

// handleHealth 回應健康檢查。
func handleHealth(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"ok"}`)
}

// registerHooksEndpoint 根據版本設定條件註冊 hooks 端點。
func registerHooksEndpoint(mux *http.ServeMux, vc VersionConfig, hookEvCh chan<- HookEvent, logger *slog.Logger) {
	if vc.HTTPHooksEnabled {
		mux.HandleFunc("/hooks/agent-event", NewHooksHandler(hookEvCh))
		logger.Info(messages.LogHooksRouteRegistered, "layer", "main")
	} else {
		mux.HandleFunc("/hooks/agent-event", newDisabledHooksHandler(logger))
		logger.Info(messages.LogHooksRouteDisabled, "layer", "main")
	}
}

// runFileWatcher 在 goroutine 中執行 FileWatcher，記錄結束原因。
func runFileWatcher(ctx context.Context, watcher *FileWatcher, logger *slog.Logger) {
	if err := watcher.Start(ctx); err != nil {
		logger.Error(messages.LogFileWatcherError, "layer", "main", "error", err)
		return
	}
	logger.Info(messages.LogFileWatcherStopped, "layer", "main")
}

// waitForShutdown 等待 SIGINT/SIGTERM 並觸發 context 取消。
func waitForShutdown(cancel context.CancelFunc, logger *slog.Logger) {
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	sig := <-sigCh
	logger.Info(messages.LogServerShutdownSignal, "layer", "main", "signal", sig.String())
	cancel()
}
