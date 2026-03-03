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
| `get_session_history` | sessionId, limit | 請求指定 session 歷史 |
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

## 效能需求

| 指標 | 目標值 |
|------|--------|
| 同時連線數 | >= 10 |
| 訊息延遲 | < 50ms（本地） |
| 重連時間 | < 5s（首次重試） |

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

*最後更新: 2026-03-03*
