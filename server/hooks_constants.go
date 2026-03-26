package main

// Hook event types (v0.2 supported)
const (
	HookEventSubagentStart  = "SubagentStart"
	HookEventSubagentStop   = "SubagentStop"
	HookEventTaskCompleted  = "TaskCompleted"
	HookEventTeammateIdle   = "TeammateIdle"
)

// KnownHookEventTypes 集中定義所有已知的 Hook 事件類型。
// 新增事件類型時，只需在此添加一行即可。
var KnownHookEventTypes = map[string]bool{
	HookEventSubagentStart: true,
	HookEventSubagentStop:  true,
	HookEventTaskCompleted: true,
	HookEventTeammateIdle:  true,
}

// HTTP Hooks channel buffer size
const HookEventChanBufferSize = 100
