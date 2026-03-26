package main

import "errors"

// Version feature thresholds
const (
	MinVersionHTTPHooks    = "2.1.63"
	MinVersionFullFeatures = "2.1.69"
)

// Claude CLI related constants
const (
	ClaudeCLICommand         = "claude"
	ClaudeCLIVersionFlag     = "--version"
	VersionCmdTimeoutSecs    = 5
	VersionPattern           = `(\d+\.\d+\.\d+)`
)

// VersionConfig represents the detected Claude Code version configuration
type VersionConfig struct {
	DetectedVersion       string
	HTTPHooksEnabled      bool
	FullFeaturesAvailable bool
}

// Sentinel errors for version detection (test use only)
// Production code should check concrete error types returned by exec.CommandContext
var (
	ErrVersionParseFailure = errors.New("version: cannot parse version from output")
	ErrVersionCmdFailed    = errors.New("version: claude command failed")
	ErrVersionCmdNotFound  = errors.New("version: claude command not found")
	ErrVersionCmdTimeout   = errors.New("version: command timed out")
)
