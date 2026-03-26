package main

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// Test group 1: ParseClaudeVersion (TC-01 to TC-07)

// TC-01: Parse standard Claude Code version output
func TestParseClaudeVersion_StandardOutput(t *testing.T) {
	output := "Claude Code 2.1.69\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.69" {
		t.Errorf("expected 2.1.69, got %s", version)
	}
}

// TC-02: Parse version with v prefix and stable label
func TestParseClaudeVersion_WithVPrefix(t *testing.T) {
	output := "claude v2.1.63 stable\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.63" {
		t.Errorf("expected 2.1.63, got %s", version)
	}
}

// TC-03: Parse version with beta suffix (should extract core version only)
func TestParseClaudeVersion_WithBetaSuffix(t *testing.T) {
	output := "Claude Code 2.1.70-beta.1\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.70" {
		t.Errorf("expected 2.1.70, got %s", version)
	}
}

// TC-04: Parse unknown format (should return error)
func TestParseClaudeVersion_UnknownFormat(t *testing.T) {
	output := "unknown format\n"
	version, err := ParseClaudeVersion(output)
	if err == nil {
		t.Errorf("expected error, got nil")
	}
	if !errors.Is(err, ErrVersionParseFailure) {
		t.Errorf("expected ErrVersionParseFailure, got %v", err)
	}
	if version != "" {
		t.Errorf("expected empty string, got %s", version)
	}
}

// TC-05: Parse empty string (should return error)
func TestParseClaudeVersion_EmptyString(t *testing.T) {
	output := ""
	version, err := ParseClaudeVersion(output)
	if err == nil {
		t.Errorf("expected error, got nil")
	}
	if !errors.Is(err, ErrVersionParseFailure) {
		t.Errorf("expected ErrVersionParseFailure, got %v", err)
	}
	if version != "" {
		t.Errorf("expected empty string, got %s", version)
	}
}

// TC-06: Parse multiline output (should extract from any line)
func TestParseClaudeVersion_MultilineOutput(t *testing.T) {
	output := "Claude Code\nVersion: 2.1.69\nAuthor: Anthropic\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.69" {
		t.Errorf("expected 2.1.69, got %s", version)
	}
}

// TC-07: Parse version without trailing newline
func TestParseClaudeVersion_NoTrailingNewline(t *testing.T) {
	output := "Claude Code 2.1.69"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.69" {
		t.Errorf("expected 2.1.69, got %s", version)
	}
}

// Test group 2: CompareVersions (TC-08 to TC-14)

// TC-08: Compare equal versions
func TestCompareVersions_EqualVersions(t *testing.T) {
	result := CompareVersions("2.1.69", "2.1.69")
	if result != 0 {
		t.Errorf("expected 0, got %d", result)
	}
}

// TC-09: Compare lower patch version
func TestCompareVersions_LowerPatch(t *testing.T) {
	result := CompareVersions("2.1.62", "2.1.63")
	if result != -1 {
		t.Errorf("expected -1, got %d", result)
	}
}

// TC-10: Compare higher patch version
func TestCompareVersions_HigherPatch(t *testing.T) {
	result := CompareVersions("2.1.70", "2.1.69")
	if result != 1 {
		t.Errorf("expected 1, got %d", result)
	}
}

// TC-11: Compare across minor version
func TestCompareVersions_CrossMinor(t *testing.T) {
	result := CompareVersions("2.1.69", "2.2.0")
	if result != -1 {
		t.Errorf("expected -1, got %d", result)
	}
}

// TC-12: Compare across major version
func TestCompareVersions_CrossMajor(t *testing.T) {
	result := CompareVersions("2.1.69", "3.0.0")
	if result != -1 {
		t.Errorf("expected -1, got %d", result)
	}
}

// TC-13: Compare at HTTP hooks threshold boundary
func TestCompareVersions_HTTPHooksThreshold(t *testing.T) {
	result := CompareVersions("2.1.63", MinVersionHTTPHooks)
	if result != 0 {
		t.Errorf("expected 0, got %d", result)
	}
}

// TC-14: Compare at full features threshold boundary
func TestCompareVersions_FullFeaturesThreshold(t *testing.T) {
	result := CompareVersions("2.1.69", MinVersionFullFeatures)
	if result != 0 {
		t.Errorf("expected 0, got %d", result)
	}
}

// Test group 3: DetectClaudeVersion (TC-15 to TC-28)

// mockCommandRunner is a test double for CommandRunner
type mockCommandRunner struct {
	output []byte
	err    error
}

func (m *mockCommandRunner) Run(ctx context.Context, name string, args ...string) ([]byte, error) {
	return m.output, m.err
}

// TC-15: Full mode - version 2.1.69 → HTTPHooksEnabled=true, FullFeaturesAvailable=true
func TestDetectClaudeVersion_FullMode(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("Claude Code 2.1.69\n")}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "2.1.69" {
		t.Errorf("expected DetectedVersion 2.1.69, got %s", config.DetectedVersion)
	}
	if !config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=true, got false")
	}
	if !config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=true, got false")
	}
}

// TC-16: Basic mode - version 2.1.63 → HTTPHooksEnabled=true, FullFeaturesAvailable=false
func TestDetectClaudeVersion_BasicMode(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("Claude Code 2.1.63\n")}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "2.1.63" {
		t.Errorf("expected DetectedVersion 2.1.63, got %s", config.DetectedVersion)
	}
	if !config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=true, got false")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-17: Degraded mode - version 2.1.62 → HTTPHooksEnabled=false, FullFeaturesAvailable=false
func TestDetectClaudeVersion_DegradedMode(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("Claude Code 2.1.62\n")}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "2.1.62" {
		t.Errorf("expected DetectedVersion 2.1.62, got %s", config.DetectedVersion)
	}
	if config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=false, got true")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-18: Basic mode upper boundary - version 2.1.68 → HTTPHooksEnabled=true, FullFeaturesAvailable=false
func TestDetectClaudeVersion_BasicModeUpperBoundary(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("Claude Code 2.1.68\n")}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "2.1.68" {
		t.Errorf("expected DetectedVersion 2.1.68, got %s", config.DetectedVersion)
	}
	if !config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=true, got false")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-19: Command not found → safe degradation with all false
func TestDetectClaudeVersion_CommandNotFound(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{err: ErrVersionCmdNotFound}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "" {
		t.Errorf("expected DetectedVersion empty, got %s", config.DetectedVersion)
	}
	if config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=false, got true")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-20: Execution failed (non-zero exit) → safe degradation
func TestDetectClaudeVersion_ExecutionFailed(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{err: ErrVersionCmdFailed}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "" {
		t.Errorf("expected DetectedVersion empty, got %s", config.DetectedVersion)
	}
	if config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=false, got true")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-21: Output cannot be parsed → safe degradation
func TestDetectClaudeVersion_OutputUnparseable(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("unknown format\n")}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "" {
		t.Errorf("expected DetectedVersion empty, got %s", config.DetectedVersion)
	}
	if config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=false, got true")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-22: Timeout → safe degradation
func TestDetectClaudeVersion_Timeout(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))

	// Create a runner that simulates timeout by returning context.DeadlineExceeded
	runner := &mockCommandRunner{err: context.DeadlineExceeded}
	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "" {
		t.Errorf("expected DetectedVersion empty, got %s", config.DetectedVersion)
	}
	if config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=false, got true")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-23: High version 3.0.0 → HTTPHooksEnabled=true, FullFeaturesAvailable=true
func TestDetectClaudeVersion_HighVersion(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("Claude Code 3.0.0\n")}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "3.0.0" {
		t.Errorf("expected DetectedVersion 3.0.0, got %s", config.DetectedVersion)
	}
	if !config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=true, got false")
	}
	if !config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=true, got false")
	}
}

// TC-24: Empty output → safe degradation
func TestDetectClaudeVersion_EmptyOutput(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("")}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "" {
		t.Errorf("expected DetectedVersion empty, got %s", config.DetectedVersion)
	}
	if config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=false, got true")
	}
	if config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=false, got true")
	}
}

// TC-26: DetectedVersion is empty string on failure
func TestDetectClaudeVersion_DetectedVersionEmpty(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{err: ErrVersionCmdFailed}

	config := DetectClaudeVersion(logger, runner)

	if config.DetectedVersion != "" {
		t.Errorf("expected DetectedVersion empty, got %s", config.DetectedVersion)
	}
}

// TC-27: Version 2.1.63 exactly at threshold (>= logic verification)
func TestDetectClaudeVersion_ExactHTTPHooksThreshold(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("Claude Code 2.1.63\n")}

	config := DetectClaudeVersion(logger, runner)

	if !config.HTTPHooksEnabled {
		t.Errorf("expected HTTPHooksEnabled=true at exact threshold 2.1.63, got false")
	}
}

// TC-28: Version 2.1.69 exactly at threshold (>= logic verification)
func TestDetectClaudeVersion_ExactFullFeaturesThreshold(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	runner := &mockCommandRunner{output: []byte("Claude Code 2.1.69\n")}

	config := DetectClaudeVersion(logger, runner)

	if !config.FullFeaturesAvailable {
		t.Errorf("expected FullFeaturesAvailable=true at exact threshold 2.1.69, got false")
	}
}

// Test group 4: DisabledHooksHandler (TC-29 to TC-31)

// TC-29: POST /hooks/agent-event returns HTTP 501 and JSON body
func TestDisabledHooksHandler_ReturnsHTTP501(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	handler := newDisabledHooksHandler(logger)

	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/hooks/agent-event", nil)

	handler(w, r)

	if w.Code != http.StatusNotImplemented {
		t.Errorf("expected HTTP 501, got %d", w.Code)
	}
}

// TC-30: Response has correct Content-Type
func TestDisabledHooksHandler_ContentType(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	handler := newDisabledHooksHandler(logger)

	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/hooks/agent-event", nil)

	handler(w, r)

	ct := w.Header().Get("Content-Type")
	if ct != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", ct)
	}
}

// TC-31: Response body contains error message
func TestDisabledHooksHandler_ErrorMessage(t *testing.T) {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	handler := newDisabledHooksHandler(logger)

	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/hooks/agent-event", nil)

	handler(w, r)

	body := w.Body.String()
	if !strings.Contains(body, "HTTP Hooks not available") {
		t.Errorf("expected error message in body, got: %s", body)
	}
	if !strings.Contains(body, "v2.1.63") {
		t.Errorf("expected v2.1.63 version requirement in body, got: %s", body)
	}
}
