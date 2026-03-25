package main

import "time"

// SessionInfo 保存單一 session 的完整狀態資訊。
// 此結構體是 Session Registry 的核心資料單元，
// 由 JSONL 事件和 HTTP Hook 事件共同填充。
//
// 欄位填充來源：
//   - JSONL 事件填充：ID, ProjectPath, Summary, EventCount, LastEventAt, FirstEventAt, FirstUserMessageAt
//   - HTTP Hook 事件填充：AgentID, AgentType, LastMessage, ParentAgentID
//   - [v0.3 預留] 欄位：AgentName
type SessionInfo struct {
	// 基礎識別（JSONL 事件填充）
	ID          string `json:"id"`
	ProjectPath string `json:"projectPath"`
	Summary     string `json:"summary,omitempty"`

	// 生命週期狀態
	Status         SessionStatus `json:"status"`
	FirstEventAt   time.Time     `json:"firstEventAt"`
	LastEventAt    time.Time     `json:"lastEventAt"`
	FirstUserMessageAt time.Time `json:"firstUserMessageAt,omitempty"`
	EventCount     int           `json:"eventCount"`

	// HTTP Hooks 提供的欄位（SubagentStart/Stop 填充）
	AgentID     string `json:"agentId,omitempty"`
	AgentType   string `json:"agentType,omitempty"`
	LastMessage string `json:"lastMessage,omitempty"` // SubagentStop 的最後回應摘要

	// [v0.3 預留] agent 父子關係追蹤
	// v0.2 中此欄位會被填充（若 Claude Code 提供），但不用於任何業務邏輯。
	// v0.3 實作 AgentNode 拓撲視圖時啟用。
	ParentAgentID string `json:"parentAgentId,omitempty"`

	// [v0.3 預留] agent 顯示名稱
	// v0.2 中永遠為空字串。v0.3 從 sessions-index.json 或 Hook 事件填充。
	AgentName string `json:"agentName,omitempty"`
}
