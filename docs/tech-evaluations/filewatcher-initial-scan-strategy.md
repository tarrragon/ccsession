# FileWatcher 初始掃描策略：Channel vs Direct Registry

> **關聯 Ticket**：0.2.0-W7-004, 0.2.0-W7-008
> **評估日期**：2026-03-27
> **決策結論**：採用 Direct Registry（方案 B）

---

## 1. 問題背景

FileWatcher 啟動時需掃描 `~/.claude/projects/` 下所有既有 JSONL 檔案（300+ 個），將對應的 session 註冊到 SessionRegistry，讓 WebSocket client 能看到完整的 session 列表。

### 問題演進

| 階段 | 做法 | 結果 |
|------|------|------|
| 原始設計 | 初始掃描讀取所有歷史事件，透過 `eventCh` 推送 | 塞滿 channel（buffer 256），block FileWatcher goroutine，後續 fsnotify 事件無法處理 |
| W7-004 修復 | 改為 `addFileSeekEnd`（只 seek 到 EOF 不讀取內容） | 解決了 channel 阻塞問題，但 session 不會被註冊 |
| 現況 | FileWatcher 啟動後只能看到有新事件的 session | 既有 session 不可見，使用者體驗不完整 |

**核心矛盾**：要讓既有 session 可見，必須在啟動時註冊它們；但透過 channel 註冊會遇到 buffer 上限問題。

---

## 2. 方案比較

### 方案 A：透過 eventCh channel 發送 discovery 事件

**資料流**：`FileWatcher → eventCh → EventDispatcher → Registry`

| 面向 | 說明 |
|------|------|
| 優點 | 保持單向資料流（低耦合）；FileWatcher 不需要知道 Registry 存在；所有事件走同一路徑容易追蹤 |
| 缺點 | channel buffer 有上限（328 個 session 直接溢出）；非阻塞寫入靜默丟棄事件難以除錯；加大 buffer 只是延後問題 |

**實測結果**：328 個 session 的 discovery 事件超過 `eventCh` buffer（256），非阻塞 `select/default` 丟棄了大部分事件，只有 1 個 active session 被註冊。

### 方案 B：直接呼叫 Registry（採用）

**資料流**：

| 路徑 | 資料流 |
|------|--------|
| 初始掃描 | `FileWatcher --scan--> Registry.UpsertFromSessionEvent()` |
| 即時監控 | `FileWatcher --runtime--> eventCh → EventDispatcher → Registry` |

| 面向 | 說明 |
|------|------|
| 優點 | 不受 channel buffer 限制；同步呼叫保證每個 session 都被註冊；批量操作用適合的機制（直接呼叫）；即時串流用適合的機制（channel） |
| 缺點 | FileWatcher 多了一個依賴（`SessionRegisterer` interface）；初始掃描和即時事件走不同路徑需要分別測試；需要定義 interface 避免 import cycle |

---

## 3. 方案對照表

| 比較維度 | 方案 A（Channel） | 方案 B（Direct Registry） |
|---------|-------------------|--------------------------|
| 資料流一致性 | 高（單一路徑） | 中（雙路徑） |
| 可靠性 | 低（buffer 溢出丟棄） | 高（同步保證） |
| 耦合度 | 低（FileWatcher 不知道 Registry） | 中（透過 interface 解耦） |
| 可擴展性 | 差（session 數量增長必然溢出） | 好（不受 buffer 限制） |
| 可測試性 | 簡單（單一路徑） | 中等（兩條路徑分別測試） |
| 除錯難度 | 高（靜默丟棄難追蹤） | 低（同步呼叫失敗即可見） |

---

## 4. 決策理由

核心判斷：**初始掃描（批量註冊）和即時監控（串流事件）是兩種不同的操作語義**。

| 操作 | 特性 | 適合的機制 |
|------|------|-----------|
| 初始掃描 | 一次性、同步、數量已知、不需要去重或分發 | 直接函式呼叫 |
| 即時監控 | 持續性、非同步、數量未知、需要去重和多消費者分發 | channel |

用同一個 channel 處理兩者，是把批量操作硬塞進串流管道。方案 B 讓每種操作用適合的機制。

---

## 5. 實作細節

### 5.1 Interface 定義（避免 import cycle）

```go
// file_watcher.go
type SessionRegisterer interface {
    UpsertFromSessionEvent(event SessionEvent)
}
```

`SessionRegistry` 已實作 `UpsertFromSessionEvent`，自動滿足此 interface。

### 5.2 addFileSeekEnd 直接呼叫 registry

registry 為 `nil` 時跳過，確保向後相容。

### 5.3 測試策略

| 測試類型 | registry 參數 | 驗證目標 |
|---------|--------------|---------|
| 初始掃描測試 | mock registry | 驗證 `UpsertFromSessionEvent` 呼叫次數和參數 |
| 即時事件測試 | `nil` | 只驗證 channel 推送行為 |

---

## 6. 風險與緩解

| 風險 | 緩解措施 |
|------|---------|
| 初始掃描和即時事件的 session 狀態可能不一致 | 兩者都呼叫同一個 `UpsertFromSessionEvent`，邏輯統一 |
| FileWatcher 對 Registry 的依賴 | 透過 `SessionRegisterer` interface 解耦，不直接依賴具體型別 |
| 未來新增消費者需要感知 discovery 事件 | discovery 只影響 session 存在性，新消費者應從 Registry 讀取而非監聽 discovery 事件 |

---

**Last Updated**: 2026-03-27
**Version**: 1.0.0
