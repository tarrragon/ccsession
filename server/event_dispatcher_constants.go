package main

import "time"

// EventSource 標識事件來源，用於優先級排序。
type EventSource string

const (
	EventSourceJSONL EventSource = "jsonl"  // 來自 JSONL file watching
	EventSourceHTTP  EventSource = "http"   // 來自 HTTP Hooks
)

// ChangeType 標識 DispatchedEvent 的變更類型。
type ChangeType string

const (
	ChangeTypeNew           ChangeType = "new"            // 新 session 被偵測到
	ChangeTypeUpdated       ChangeType = "updated"        // SessionInfo 欄位更新
	ChangeTypeStatusChanged ChangeType = "status_changed" // Status 狀態轉換
)

// 去重窗口大小：相同 dedup key 在 5 秒窗口內被視為重複
const DedupWindowDuration = 5 * time.Second

// 去重表清理間隔：防止記憶體無限增長（30 秒清理一次）
const DedupCleanupInterval = 30 * time.Second

// 輸出 channel 緩衝大小：推送給 WebSocket Hub 的事件緩衝
const DispatcherOutChanSize = 200

// Log 訊息常數（開發者用，英文）
const (
	LogDispatcherStarted           = "EventDispatcher started"
	LogDispatcherStopped           = "EventDispatcher stopped"
	LogSessionEventProcessed       = "session event processed"
	LogHookEventProcessed          = "hook event processed"
	LogDedupIgnoredEvent           = "event deduplicated and ignored"
	LogStatusTransition            = "session status transitioned"
	LogDedupTableCleanup           = "deduplication table cleaned up"
	LogDispatcherOutChanFull       = "out channel full, event dropped but registry updated"
	LogDispatcherInternalError     = "EventDispatcher internal error"
	LogUnexpectedEventSourceFormat = "unexpected event source format"
)
