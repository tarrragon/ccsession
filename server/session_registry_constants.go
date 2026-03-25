package main

import "time"

// SessionStatus 表示 session 的生命週期狀態。
// 狀態機轉換規則：
//   - active: session 正在活躍運作，< 2 分鐘無新事件或新 SubagentStart/SubagentStop 事件
//   - idle: session 暫時閒置，2-30 分鐘無新事件或收到 TeammateIdle 事件
//   - completed: session 已結束，30 分鐘以上無事件或收到 SubagentStop 事件（即時）
type SessionStatus string

const (
	SessionStatusActive    SessionStatus = "active"
	SessionStatusIdle      SessionStatus = "idle"
	SessionStatusCompleted SessionStatus = "completed"
)

// 狀態轉換超時閾值
const (
	// ActiveThreshold 定義 session 被判定為 active 的最長時間。
	// 超過此時間無新事件，狀態轉為 idle。
	ActiveThreshold = 2 * time.Minute

	// IdleThreshold 定義 session 被判定為 idle 的最長時間。
	// 超過此時間無新事件，狀態轉為 completed。
	IdleThreshold = 30 * time.Minute
)

// Session Summary 截斷長度
const MaxSummaryLength = 100

// 狀態掃描週期（定時觸發狀態機評估）
const StatusScanInterval = 30 * time.Second
