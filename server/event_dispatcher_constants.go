package main

import "time"

type EventSource string

const (
	EventSourceJSONL EventSource = "jsonl"
	EventSourceHTTP  EventSource = "http"
)

type ChangeType string

const (
	ChangeTypeNew           ChangeType = "new"
	ChangeTypeUpdated       ChangeType = "updated"
	ChangeTypeStatusChanged ChangeType = "status_changed"
)

const (
	DedupWindowDuration  = 5 * time.Second
	DedupCleanupInterval = 30 * time.Second
	DispatcherOutChanSize = 200
)

// Log messages
const (
	LogDispatcherStarted    = "event dispatcher started"
	LogDispatcherStopped    = "event dispatcher stopped"
	LogJSONLEventProcessed  = "JSONL event processed"
	LogHookEventProcessed   = "hook event dispatched"
	LogEventDeduplicated    = "event deduplicated, skipping"
	LogOutChFull            = "output channel full, dropping event"
	LogDedupTableCleaned    = "dedup table cleaned"
	LogStatusScanCompleted  = "status scan completed"
	LogTimestampParseFailed = "failed to parse hook event timestamp"
	LogSessionEvChClosed    = "session event channel closed"
	LogHookEvChClosed       = "hook event channel closed"
)
