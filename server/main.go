package main

import (
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
)

func main() {
	// Initialize logger with structured logging
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))

	// Detect Claude Code version (must be first, before other initialization)
	versionConfig := DetectClaudeVersion(logger, &defaultCommandRunner{})

	port := "8765"
	if p := os.Getenv("PORT"); p != "" {
		port = p
	}

	// Health check endpoint (always available)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok"}`)
	})

	// Conditional HTTP Hooks endpoint based on version
	if versionConfig.HTTPHooksEnabled {
		// HTTP Hooks are enabled, use actual handler
		// TODO: Implement actual HTTP hooks handler
		logger.Info("HTTP Hooks route registered", "layer", "main")
		http.HandleFunc("/hooks/agent-event", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			fmt.Fprintf(w, `{"status":"received"}`)
		})
	} else {
		// HTTP Hooks are disabled, use degraded handler
		http.HandleFunc("/hooks/agent-event", newDisabledHooksHandler(logger))
		logger.Info("HTTP Hooks disabled, degraded handler registered", "layer", "main")
	}

	addr := "localhost:" + port
	logger.Info("ccsession-monitor starting", "layer", "main", "addr", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		logger.Error("server failed", "layer", "main", "error", err)
		log.Fatalf("server failed: %v", err)
	}
}
