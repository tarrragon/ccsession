package main

// Hook event types (v0.2 supported)
const (
	HookEventSubagentStart  = "SubagentStart"
	HookEventSubagentStop   = "SubagentStop"
	HookEventTaskCompleted  = "TaskCompleted"
	HookEventTeammateIdle   = "TeammateIdle"
)

// HTTP Hooks channel buffer size
const HookEventChanBufferSize = 100
