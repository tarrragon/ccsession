Feature: UC-009 WebSocket 通訊

  Background:
    Given Go Backend 已啟動並監聽 WebSocket port（預設 8765）
    And Flutter Frontend 已啟動

  Scenario: Frontend 自動連線到 Backend
    Given Frontend 啟動時無已連接的 WebSocket 連線
    When Frontend 自動連線到 ws://localhost:8765/ws
    Then 連線建立成功
    And Frontend 顯示連線狀態為「已連線」（綠色圓點）
    And Frontend 無需手動干預

  Scenario: 連線建立後接收完整 session 列表
    Given Frontend 與 Backend 建立 WebSocket 連線
    When Backend 接受連線，建立 Client 記錄
    Then Backend 推送完整的 session_list 快照
    And session_list 包含所有 session 的 SessionInfo
    And Frontend 收到後更新 UI 狀態

  Scenario: Frontend 訂閱特定 session 的即時事件
    Given WebSocket 連線已建立
    When Frontend 發送 subscribe_session 訊息（含 sessionId）
    Then Backend 將該 Client 加入 session 的訂閱列表
    And 後續該 session 的新事件推送給此 Client

  Scenario: Frontend 取消訂閱
    Given Frontend 已訂閱某個 session
    When Frontend 發送 unsubscribe_session 訊息
    Then Backend 將該 Client 從訂閱列表移除
    And 後續該 session 的事件不再推送給此 Client

  Scenario: Frontend 請求 session 歷史記錄
    Given Frontend 需要載入某個 session 的歷史
    When Frontend 發送 get_session_history 訊息（含 sessionId, limit）
    Then Backend 讀取 JSONL 檔案
    And Backend 取最近 limit 條記錄
    And Backend 回傳 session_history 訊息（SessionEvent 陣列）

  Scenario: 分頁載入支援 before 參數
    Given Frontend 已載入第一頁（最近 100 條）
    When Frontend 需要載入更早的記錄
    Then Frontend 發送 get_session_history（sessionId, limit=100, before=earliest_timestamp）
    And Backend 返回 before 時間戳之前的事件（排他比較）

  Scenario: 心跳機制防止假死連線
    Given WebSocket 連線已建立
    When 每 30 秒
    Then Backend 發送 ping 訊息
    And Frontend 自動回應 pong 訊息

  Scenario: 連線超時偵測
    Given Backend 發送 ping 訊息
    When Frontend 連續 3 次無 pong 回應（90 秒）
    Then Backend 主動關閉該連線
    And Backend 釋放相關資源

  Scenario: Frontend 斷線後自動重連
    Given WebSocket 連線中斷
    When Frontend 偵測到斷線
    Then Frontend 顯示「已斷線」（紅色圓點）
    And Frontend 啟動重連機制（指數退避：1s, 2s, 4s, 8s, 16s, 最大 30s）

  Scenario: 重連成功後恢復狀態
    Given Frontend 重連成功
    When 重新連線到 Backend
    Then Frontend 重新取得 session_list
    And Frontend 重新訂閱之前訂閱的 session
    And Frontend UI 恢復為「已連線」

  Scenario: 多個 Frontend Client 同時連線
    Given 多個 Flutter 實例同時連線
    When 每個 Client 獨立管理訂閱
    Then Backend 為每個 Client 維護單獨的訂閱清單
    And 事件廣播到所有已訂閱的 Client

  Scenario: session_event 推送給訂閱者
    Given 某個 session 有新事件
    When Backend 推送 session_event 訊息
    Then 只推送給已訂閱該 session 的 Client
    And 未訂閱的 Client 不接收該事件
    And 多個訂閱者同時接收（廣播）

  Scenario: session_status_change 推送
    Given 某個 session 狀態變更（如 active → idle）
    When Backend 推送 session_status_change 訊息
    Then 訊息包含 sessionId 和 newStatus
    And 推送給所有連線的 Client（不限訂閱）
    And Frontend 更新 session 列表中的狀態指示燈

  Scenario: 無效訊息格式時的錯誤回應
    Given Client 發送無法解析的訊息格式
    When Backend 收到訊息
    Then Backend 回傳 error 訊息
    And 訊息包含錯誤描述和 error code
    And 連線不被中斷

  Scenario: 請求不存在的 session 時的錯誤
    Given Client 請求不存在的 sessionId 的歷史
    When Backend 收到請求
    Then Backend 回傳 error 訊息（session not found）
    And 連線保持正常

  Scenario: Backend 未啟動時 Frontend 重連
    Given Go Backend 未啟動
    When Frontend 嘗試連線
    Then 連線逾時失敗
    And Frontend 顯示「無法連線到監控服務」
    And Frontend 持續重試連線（指數退避）

  Scenario: WebSocket 連線數上限檢查
    Given Backend 設定連線數上限為 10
    When 已有 10 個 Client 連線
    And 第 11 個 Client 嘗試連線
    Then Backend 拒絕新連線
    And 回傳 HTTP 503（Service Unavailable）
    And 附帶 error message 說明連線已滿

  Scenario: 單連線記憶體預算
    Given 建立 1 個 WebSocket 連線
    When 連線建立並訂閱多個 session
    Then 單連線記憶體使用 < 32 KB
    And 包含：連線本身（4 KB）、讀寫緩衝區（8 KB）、訂閱狀態（1 KB）、發送佇列（16 KB）

  Scenario: 10 連線下的廣播延遲
    Given 10 個 Client 同時訂閱某個 session
    When 新事件到達
    Then Backend 廣播 session_event 給所有 10 個 Client
    And 廣播完成時間 < 10ms
    And 所有 Client 近乎同時接收

  Scenario: 發送佇列滿時的行為
    Given 某個 Client 的發送佇列已滿
    When 新事件準備推送
    Then Backend 丟棄該 Client 的最舊訊息
    And 新訊息入隊
    And 其他 Client 的推送不受影響

  Scenario: 廣播失敗恢復
    Given 正在廣播事件給多個 Client
    When 某個 Client 的發送失敗
    Then Backend 記錄該 Client 的失敗
    And 繼續廣播給其他 Client
    Then 該 Client 在心跳超時時被移除

  Scenario: Client → Server 訊息格式驗證
    Given Frontend 發送各類訊息（get_session_list、subscribe_session 等）
    When Backend 接收訊息
    Then Backend 驗證 JSON 格式
    And Backend 驗證必填欄位
    When 格式或欄位缺失
    Then Backend 回傳 error 訊息

  Scenario: Server → Client 訊息類型
    Given Backend 需要推送訊息給 Client
    Then 可使用以下 type：
      | type | 說明 |
      | session_list | 完整 session 列表（連線建立或請求時） |
      | session_event | 新事件（已訂閱） |
      | session_history | 歷史記錄（主動請求） |
      | session_status_change | 狀態變更（廣播） |
      | error | 錯誤訊息 |

  Scenario: Phase 3+ 預留 - 後端搜尋支援
    Given Phase 3+ 實作計畫中
    When 對話搜尋擴充到後端全文搜尋
    Then 預留 search_session action（Client → Server）
    And 預留 search_results type（Server → Client）
    And 搜尋結果包含匹配片段及位置高亮（highlights）

  Scenario: WebSocket 架構適用本地使用場景
    Given 本系統為本地監控工具（非 SaaS）
    When 使用場景為 1 位開發者、1-2 個瀏覽器分頁
    Then WebSocket 設計適配小規模連線
    And 預期同時連線數 1-5，設計上限 10
    And 無需支援高併發（數百或數千連線）

  Scenario: 重連成功後命令撤回
    Given Frontend 在重連過程中發送訂閱命令
    When 重連中斷或延遲
    Then Frontend 不會重複發送已發送的訂閱命令
    And 重連成功後恢復正確的訂閱狀態
