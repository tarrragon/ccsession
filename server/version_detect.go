package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// ParseClaudeVersion extracts the semantic version from claude --version output.
// It uses VersionPattern to find the first MAJOR.MINOR.PATCH version string.
//
// Examples:
//   - "Claude Code 2.1.69\n" → ("2.1.69", nil)
//   - "claude v2.1.63 stable\n" → ("2.1.63", nil)
//   - "Claude Code 2.1.70-beta.1\n" → ("2.1.70", nil)
//   - "unknown format\n" → ("", ErrVersionParseFailure)
func ParseClaudeVersion(output string) (string, error) {
	re := regexp.MustCompile(VersionPattern)
	matches := re.FindStringSubmatch(output)
	if len(matches) < 2 {
		return "", ErrVersionParseFailure
	}
	return matches[1], nil
}

// CompareVersions compares two semantic version strings.
// Returns: -1 if a < b, 0 if a == b, 1 if a > b.
// Format errors result in safe degradation (returns 0).
func CompareVersions(a, b string) int {
	aParts := parseVersionComponents(a)
	bParts := parseVersionComponents(b)

	// Safe degradation: if either version is unparseable, return equal
	if aParts == nil || bParts == nil {
		return 0
	}

	// Compare major, minor, patch in order
	for i := 0; i < 3; i++ {
		if aParts[i] < bParts[i] {
			return -1
		}
		if aParts[i] > bParts[i] {
			return 1
		}
	}

	return 0
}

// parseVersionComponents parses a version string into [major, minor, patch] integers.
// Returns nil if the version string is malformed.
func parseVersionComponents(version string) *[3]int {
	parts := strings.Split(strings.TrimSpace(version), ".")
	if len(parts) < 3 {
		return nil
	}

	result := &[3]int{}
	for i := 0; i < 3; i++ {
		// Extract only the numeric part from the segment (e.g., "70-beta.1" → "70")
		segment := parts[i]
		for j := 0; j < len(segment); j++ {
			if segment[j] < '0' || segment[j] > '9' {
				segment = segment[:j]
				break
			}
		}

		num, err := strconv.Atoi(segment)
		if err != nil || segment == "" {
			return nil
		}
		result[i] = num
	}

	return result
}

// CommandRunner abstracts external command execution for testing purposes.
type CommandRunner interface {
	Run(ctx context.Context, name string, args ...string) (output []byte, err error)
}

// defaultCommandRunner executes actual external commands.
type defaultCommandRunner struct{}

// Run executes an external command with the given context and arguments.
func (r *defaultCommandRunner) Run(ctx context.Context, name string, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, name, args...)
	return cmd.CombinedOutput()
}

// DetectClaudeVersion detects the Claude Code version by executing claude --version.
// It does not return errors; all failure scenarios result in safe degradation with logs.
// Version thresholds:
//   - < v2.1.63 → HTTPHooksEnabled=false, FullFeaturesAvailable=false
//   - [v2.1.63, v2.1.69) → HTTPHooksEnabled=true, FullFeaturesAvailable=false
//   - >= v2.1.69 → HTTPHooksEnabled=true, FullFeaturesAvailable=true
func DetectClaudeVersion(logger *slog.Logger, runner CommandRunner) VersionConfig {
	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(VersionCmdTimeoutSecs)*time.Second)
	defer cancel()

	// Execute claude --version
	output, err := runner.Run(ctx, ClaudeCLICommand, ClaudeCLIVersionFlag)

	// Handle execution failures with safe degradation
	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			logger.Warn(LogVersionCmdTimeout, "layer", "version_detect")
			return VersionConfig{}
		}
		logger.Warn(LogVersionCmdFailed, "layer", "version_detect", "error", err)
		return VersionConfig{}
	}

	// Parse version string
	version, err := ParseClaudeVersion(string(output))
	if err != nil {
		logger.Warn(LogVersionParseFailed, "layer", "version_detect", "output", string(output))
		return VersionConfig{}
	}

	// Determine feature flags based on version comparison
	config := VersionConfig{
		DetectedVersion: version,
	}

	// Check if HTTP hooks are enabled (>= v2.1.63)
	if CompareVersions(version, MinVersionHTTPHooks) >= 0 {
		config.HTTPHooksEnabled = true

		// Check if full features are available (>= v2.1.69)
		if CompareVersions(version, MinVersionFullFeatures) >= 0 {
			config.FullFeaturesAvailable = true
			logger.Info(LogVersionDetected,
				"layer", "version_detect",
				"version", version,
				"http_hooks", true,
				"full_features", true)
		} else {
			logger.Info(LogVersionDetected,
				"layer", "version_detect",
				"version", version,
				"http_hooks", true,
				"full_features", false)
			logger.Warn(LogFullFeaturesPartial,
				"layer", "version_detect",
				"version", version)
		}
	} else {
		logger.Warn(LogHTTPHooksDisabled,
			"layer", "version_detect",
			"version", version,
			"min_version", MinVersionHTTPHooks)
	}

	return config
}

// newDisabledHooksHandler returns an HTTP 501 handler for when HTTP Hooks are disabled.
func newDisabledHooksHandler(logger *slog.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logger.Info(LogHTTPHooksNotAvailable,
			"layer", "version_detect",
			"method", r.Method,
			"path", r.URL.Path)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)

		response := map[string]string{
			"error": "HTTP Hooks not available: requires Claude Code v2.1.63+",
		}
		json.NewEncoder(w).Encode(response)
	}
}
