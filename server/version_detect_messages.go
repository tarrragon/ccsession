package main

// Version detection layer log messages
const (
	LogVersionDetected       = "Claude Code version detected"
	LogHTTPHooksEnabled      = "HTTP Hooks enabled"
	LogFullFeaturesEnabled   = "full agent fields available"
	LogFullFeaturesPartial   = "HTTP Hooks enabled with partial features: agent_id/agent_type fields may be incomplete, upgrade to v2.1.69+ for full support"
	LogHTTPHooksDisabled     = "HTTP Hooks disabled: Claude Code version below minimum requirement, upgrade to v2.1.63+ to enable"
	LogVersionCmdNotFound    = "claude command not found, falling back to JSONL-only mode"
	LogVersionCmdFailed      = "claude --version command failed, falling back to JSONL-only mode"
	LogVersionParseFailed    = "cannot parse Claude Code version from output, falling back to JSONL-only mode"
	LogVersionCmdTimeout     = "claude --version timed out, falling back to JSONL-only mode"
	LogHTTPHooksNotAvailable = "HTTP Hooks request received but feature is disabled"
)
