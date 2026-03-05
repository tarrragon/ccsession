# UC-009: WebSocket 通訊

## 基本資訊

| 項目 | 說明 |
|------|------|
| **ID** | UC-009 |
| **名稱** | WebSocket 通訊 |
| **Actor** | System (Go Backend + Flutter Frontend) |
| **優先級** | P0 |
| **元件** | 雙端 |
| **依賴** | UC-008 (Session State) |

---

## 目標

建立穩定的雙向即時通訊通道，讓 Frontend 能即時接收 Backend 的事件推送，
並能主動請求 session 列表和歷史記錄。

---

## 前置條件

1. Go Backend 已啟動並監聽 WebSocket port
2. Flutter Frontend 已啟動

---

## 主要流程（Happy Path）

### 9.1 連線建立

1. Frontend 啟動後自動連線到 `ws://localhost:{port}/ws`
2. Backend 接受連線，建立 Client 記錄
3. Backend 推送完整的 `session_list` 快照
4. Frontend 更新 UI 狀態為「已連線」

### 9.2 訂閱 Session

1. Frontend 發送 `subscribe_session` 訊息（含 sessionId）
2. Backend 將該 Client 加入 session 的訂閱列表
3. 後續該 session 的新事件會推送給此 Client

### 9.3 取消訂閱

1. Frontend 發送 `unsubscribe_session` 訊息
2. Backend 將該 Client 從訂閱列表移除

### 9.4 請求歷史記錄

1. Frontend 發送 `get_session_history` 訊息（含 sessionId, limit）
2. Backend 讀取 JSONL 檔案，取最近 limit 條記錄
3. Backend 回傳 `session_history` 訊息

### 9.5 心跳機制

1. 每 30 秒 Backend 發送 ping
2. Frontend 回應 pong
3. 連續 3 次無回應 → Backend 關閉該連線

---

## 替代流程

### A1: 多 Client 同時連線

1. 多個 Flutter 實例同時連線
2. 每個 Client 獨立管理訂閱
3. 事件廣播到所有已訂閱的 Client

### A2: Client 斷線重連

1. WebSocket 連線中斷
2. Frontend 顯示「已斷線」
3. 指數退避重連：1s, 2s, 4s, 8s, 16s, 最大 30s
4. 重連成功後：
   - 重新取得 session_list
   - 重新訂閱之前訂閱的 session
   - UI 恢復為「已連線」

---

## 訊息協議

### Client → Server

| action | 參數 | 說明 |
|--------|------|------|
| `get_session_list` | 無 | 請求所有 session 列表 |
| `get_session_history` | sessionId, limit, before (optional) | 請求指定 session 歷史；before 為 timestamp，用於載入此時間點之前的訊息 |
| `subscribe_session` | sessionId | 訂閱即時事件 |
| `unsubscribe_session` | sessionId | 取消訂閱 |

### Server → Client

| type | data 內容 | 觸發時機 |
|------|----------|---------|
| `session_list` | SessionInfo[] | 連線建立 / 主動請求 |
| `session_event` | SessionEvent | 新事件產生（已訂閱） |
| `session_history` | SessionEvent[] | 主動請求 |
| `session_status_change` | sessionId, newStatus | 狀態變更 |
| `error` | message, code | 請求處理失敗 |

**[Phase 3+ 預留] 後端搜尋支援**：
- 搜尋功能在 Phase 1-2 採用純前端實現（搜尋已載入內容），Phase 3+ 擴充後端全文搜尋
- 預留 Client -> Server action：`search_session`，參數為 `sessionId`（必填）、`query`（搜尋字串，必填）、`limit`（回傳上限，選填，預設 50）、`before`（時間戳游標，選填，用於分頁）
- 預留 Server -> Client type：`search_results`，data 內容為 `{ sessionId, query, matches: [{ event: SessionEvent, highlights: [{ field, offset, length }] }], hasMore: boolean }`
- `highlights` 陣列標記匹配文字在 event content 中的位置，供前端高亮渲染
- 目前在 Phase 1-2 範圍內不實作此訊息類型，Phase 3+ 啟動時再定義完整的錯誤處理和效能需求

---

## 例外流程

### E1: Backend 未啟動

1. Frontend 連線逾時
2. 顯示「無法連線到監控服務」
3. 持續重試

### E2: 無效的訊息格式

1. Client 發送無法解析的訊息
2. Backend 回傳 `error` 訊息
3. 不中斷連線

### E3: 請求不存在的 Session

1. Client 請求不存在的 sessionId 的歷史
2. Backend 回傳 `error` 訊息（session not found）

---

## WebSocket 架構預期

### 使用場景定位

本系統為本地監控工具（非 SaaS），Go Backend 運行在開發者本機。
典型使用情境：1 位開發者開啟 1-2 個瀏覽器分頁，監控多個 Claude Code session。

### 同時連線數預期

| 場景 | 預期連線數 | 說明 |
|------|-----------|------|
| 典型使用 | 1-2 | 單一開發者，1 個主監控分頁 + 偶爾第 2 分頁 |
| 多裝置 | 3-5 | 桌面瀏覽器 + 行動裝置 + 額外分頁 |
| 設計上限 | 10 | 預留充足餘量，超過此數量不保證效能 |

設計決策：以 5 個連線為效能調校基準，10 個連線為設計上限。
不需要考慮數百或數千連線的高併發場景。

### 每連線記憶體預算

| 項目 | 預算 | 說明 |
|------|------|------|
| WebSocket 連線本身 | ~4 KB | goroutine stack + 連線狀態 |
| 讀寫緩衝區 | ~8 KB | 讀 4 KB + 寫 4 KB |
| 訂閱狀態 | ~1 KB | 訂閱的 session ID 集合 |
| 發送佇列 | ~16 KB | 待發送訊息緩衝（channel buffer） |
| **單連線合計** | **~29 KB** | |
| **10 連線合計** | **~290 KB** | 遠低於本地應用可用記憶體 |

注意：Session 資料快取（已解析的 JSONL 內容）為全域共享，不計入單連線預算。
全域快取大小取決於監控的 session 數量，與連線數無關。

### 連線管理策略

| 機制 | 參數 | 說明 |
|------|------|------|
| 心跳間隔 | 30 秒 | Backend 發送 ping，Frontend 回應 pong |
| 心跳超時 | 連續 3 次無回應（90 秒） | Backend 主動關閉該連線，釋放資源 |
| 閒置超時 | 不設定 | 本地工具無需閒置斷線，由心跳機制處理假死 |
| 斷線重連（Frontend） | 指數退避 1s-30s | 詳見替代流程 A2 |
| 連線數上限檢查 | 超過 10 時拒絕新連線 | 回傳 HTTP 503，附帶 error message |

### 廣播策略

事件推送採用扇出（fan-out）模式：每個 session 事件向所有訂閱該 session 的 Client 廣播。
單一 Client 發送失敗不影響其他 Client 接收。
發送佇列滿時丟棄最舊訊息（而非阻塞其他 Client）。

---

## 效能需求

| 指標 | 目標值 | 說明 |
|------|--------|------|
| 同時連線數 | >= 10 | 設計上限，典型使用 1-5 |
| 事件推送延遲 | < 50ms（本地） | 從檔案變更偵測到 Client 接收 |
| 重連時間 | < 5s（首次重試） | Frontend 指數退避策略 |
| 單連線記憶體 | < 32 KB | 含緩衝區和訂閱狀態 |
| 廣播延遲（10 連線） | < 10ms | 扇出到所有已訂閱 Client 的額外開銷 |

---

## 驗收條件

- [ ] Frontend 啟動後自動連線
- [ ] 連線建立後收到完整 session list
- [ ] 訂閱機制正常運作
- [ ] 取消訂閱後不再收到該 session 事件
- [ ] 歷史記錄請求正確回傳
- [ ] 斷線後自動重連
- [ ] 重連後狀態正確恢復
- [ ] 心跳機制防止假死連線
- [ ] 支援 10+ 個 Client 同時連線
- [ ] 無效訊息不導致連線中斷

---

*最後更新: 2026-03-05*
