Feature: UC-010 結構化日誌輸出

  Background:
    Given 系統已啟動

  # 驗收條件 1：Go Backend 啟動時 log 初始化完成，level 可由 CLI flag 或環境變數設定
  Scenario: Go Backend 啟動時 log 初始化完成
    Given Go Backend 即將啟動
    When Go Backend 啟動
    Then log 初始化完成
    And log level 可由 CLI flag 設定
    And log level 可由環境變數設定

  Scenario: 使用 CLI flag 設定 Go log level
    Given Go Backend 啟動時指定 log level flag（--loglevel=DEBUG）
    When Backend 啟動
    Then Backend 輸出 DEBUG 及以上等級的 log
    And 對應的 WARN、INFO、ERROR log 也輸出

  Scenario: 使用環境變數設定 Go log level
    Given Go Backend 啟動前設定環境變數 LOG_LEVEL=ERROR
    When Backend 啟動
    Then Backend 只輸出 ERROR 等級的 log
    And DEBUG、INFO、WARN log 不輸出

  Scenario: Go log level 預設值為 INFO
    Given Go Backend 啟動時未指定 log level
    And 環境變數未設定 LOG_LEVEL
    When Backend 啟動
    Then Backend 預設輸出 INFO 及以上等級的 log
    And DEBUG log 不輸出

  # 驗收條件 2：Flutter 啟動時 log 初始化完成，release 模式自動降級為 INFO 以上
  Scenario: Flutter Debug 模式 log 初始化完成
    Given Flutter 在 debug 模式啟動
    When Flutter 啟動
    Then log 初始化完成
    And DEBUG log 已啟用
    And INFO、WARN、ERROR log 已啟用

  Scenario: Flutter Release 模式自動降級為 INFO 以上
    Given Flutter 在 release 模式啟動
    When Flutter 啟動
    Then log 初始化完成
    And DEBUG log 自動禁用
    And INFO、WARN、ERROR log 保持啟用

  # 驗收條件 3：File Watcher 層：偵測到新檔案時輸出 INFO log
  Scenario: File Watcher 偵測到新 session 檔案時輸出 INFO log
    Given File Watcher 在監視 ~/.claude/projects/ 目錄
    When 新 session 檔案被建立（例如 abc-123.jsonl）
    Then File Watcher 立即輸出 INFO 等級 log
    And log 包含欄位：filePath、sessionID
    And log 訊息為：「new session file detected」

  # 驗收條件 4：File Watcher 層：每次讀取新行時輸出 DEBUG log（含 offset）
  Scenario: File Watcher 讀取新行時輸出 DEBUG log
    Given File Watcher 正在監視某個 session 檔案
    And 檔案中已有若干行
    When 檔案新增一行內容
    Then File Watcher 偵測到新行
    And 輸出 DEBUG 等級 log
    And log 包含欄位：sessionID、offset、bytesRead、lineCount
    And offset 值等於上次讀取位置加上本次讀取位元組數

  Scenario: File Watcher 不完整 JSON 行時輸出 DEBUG log
    Given File Watcher 正在監視某個 session 檔案
    When 檔案新增不完整的 JSON 行（缺少換行符，等待下次讀取）
    Then File Watcher 偵測到讀取
    And 輸出 DEBUG 等級 log
    And log 包含欄位：sessionID
    And 訊息為：「incomplete JSON line, waiting for next read」

  # 驗收條件 5：JSONL Parser 層：解析失敗時輸出 ERROR log（含 rawLine）
  Scenario: JSONL Parser 解析失敗時輸出 ERROR log
    Given JSONL Parser 要解析某一行
    When 該行是無效 JSON 格式（例如 malformed JSON）
    Then Parser 輸出 ERROR 等級 log
    And log 包含欄位：sessionID、rawLine、error
    And error 欄位包含詳細的 JSON 解析錯誤訊息

  Scenario: JSONL Parser 成功解析時輸出 DEBUG log
    Given JSONL Parser 要解析某一行
    When 該行是有效 JSON
    Then Parser 輸出 DEBUG 等級 log
    And log 包含欄位：sessionID、type、toolName（若為 tool_use 事件）
    And 訊息為：「parsed event successfully」

  # 驗收條件 6：Session Manager 層：每次狀態轉換輸出 INFO log（含 from/to）
  Scenario: Session Manager 狀態轉換輸出 INFO log
    Given Session Manager 正在管理某個 session
    And session 目前狀態為「active」
    When session 狀態轉換為「idle」
    Then Session Manager 輸出 INFO 等級 log
    And log 包含欄位：sessionID、from、to、reason
    And from 值為「active」
    And to 值為「idle」

  Scenario: Session Manager 新增 session 時輸出 INFO log
    Given Session Manager 偵測到新 session
    When session 被新增
    Then Session Manager 輸出 INFO 等級 log
    And log 包含欄位：sessionID、projectPath
    And 訊息為：「session added」

  Scenario: Session Manager 移除 session 時輸出 INFO log
    Given Session Manager 管理某個 session
    When session 被移除（檔案刪除或其他原因）
    Then Session Manager 輸出 INFO 等級 log
    And log 包含欄位：sessionID、reason
    And 訊息為：「session removed」

  # 驗收條件 7：WS Server 層：Client 連線/斷線輸出 INFO log
  Scenario: WebSocket Server 新增 Client 連線時輸出 INFO log
    Given WebSocket Server 正在監聽連線
    When 新 Client 連線成功
    Then WebSocket Server 輸出 INFO 等級 log
    And log 包含欄位：clientAddr、totalClients
    And totalClients 數量等於當前連線總數

  Scenario: WebSocket Server Client 斷線時輸出 INFO log
    Given WebSocket Server 有 N 個連線 Client
    When 某個 Client 斷線
    Then WebSocket Server 輸出 INFO 等級 log
    And log 包含欄位：clientAddr、reason
    And 訊息為：「client disconnected」

  Scenario: WebSocket Server 推送事件時輸出 DEBUG log
    Given WebSocket Server 有已連線的 Client
    When Server 推送事件給 Client
    Then Server 輸出 DEBUG 等級 log
    And log 包含欄位：clientAddr、eventType、sessionID
    And 訊息為：「pushing event to client」

  Scenario: WebSocket Server 廣播失敗時輸出 ERROR log
    Given WebSocket Server 正在廣播事件
    When 廣播給某個 Client 失敗
    Then Server 輸出 ERROR 等級 log
    And log 包含欄位：clientAddr、error
    And error 欄位包含失敗原因

  # 驗收條件 8：Flutter WS Client：連線/斷線輸出 INFO log
  Scenario: Flutter WebSocket Client 連線建立時輸出 INFO log
    Given Flutter Frontend 啟動
    When WebSocket Client 連線到 Backend（ws://localhost:8765/ws）
    Then Client 輸出 INFO 等級 log
    And log 包含欄位：serverUrl
    And 訊息為：「WebSocket connected」

  Scenario: Flutter WebSocket Client 斷線時輸出 INFO log
    Given Flutter Frontend 已連線到 Backend
    When WebSocket 連線中斷
    Then Client 輸出 INFO 等級 log
    And log 包含欄位：reason、willRetry、retryIn
    And willRetry 值為 true 或 false
    And retryIn 值為下次重試延遲時間（秒）

  Scenario: Flutter WebSocket Client 收到訊息時輸出 DEBUG log
    Given Flutter Frontend 已連線
    When Client 收到來自 Backend 的訊息
    Then Client 輸出 DEBUG 等級 log
    And log 包含欄位：type、dataSize
    And type 值為訊息型別（session_list、session_event 等）

  Scenario: Flutter WebSocket Client 解析失敗時輸出 ERROR log
    Given Flutter Frontend 已連線
    When Client 收到無法解析的訊息
    Then Client 輸出 ERROR 等級 log
    And log 包含欄位：rawMessage、error
    And error 欄位包含詳細的解析錯誤訊息

  # 驗收條件 9：Flutter Event Mapper：收到訊息時輸出 DEBUG log
  Scenario: Event Mapper 成功映射事件時輸出 DEBUG log
    Given Flutter Event Mapper 收到 WebSocket 訊息
    When Event Mapper 成功將訊息映射到 domain 事件
    Then Mapper 輸出 DEBUG 等級 log
    And log 包含欄位：type、sessionID
    And 訊息為：「event mapped successfully」

  # 驗收條件 10：所有 log 為結構化 JSON 格式
  Scenario: Go Backend log 為 JSON 格式
    Given Go Backend 輸出 log
    When 讀取 Backend stderr 輸出
    Then 每一行 log 都是有效的 JSON 物件
    And JSON 包含標準欄位：level、time、layer、msg
    And 可被標準 JSON parser 解析

  Scenario: Flutter log 為 JSON 格式
    Given Flutter Frontend 輸出 log
    When 讀取 Flutter log 輸出
    Then 每一行 log 都是有效的 JSON 物件
    And JSON 包含標準欄位：level、time、logger
    And 可被標準 JSON parser 解析

  Scenario: Log JSON 包含完整必填欄位
    Given 系統輸出 log
    When 檢查任意一條 log 記錄
    Then JSON 包含以下必填欄位：
      | 欄位 | 說明 |
      | level | Log 等級（DEBUG/INFO/WARN/ERROR） |
      | time | ISO 8601 時間戳 |
      | msg | 人類可讀的訊息 |
    And JSON 不包含使用者對話內容

  # 驗收條件 11：Log 不包含使用者對話內容（避免敏感資料外洩）
  Scenario: Log 不包含使用者對話內容
    Given 系統正在處理 session 事件
    When Backend 輸出 log
    Then log 中不包含 userMessage 或 assistantMessage 的完整內容
    And 允許記錄訊息相關的中繼資料（如 type、timestamp）
    And 不允許洩漏對話文本

  Scenario: Flutter State log 不包含敏感使用者資料
    Given Flutter 正在更新 state
    When Flutter 輸出 state 相關的 debug log
    Then log 記錄 state 的結構和大小
    And 不記錄具體的對話內容
    And 允許記錄 session 中的事件計數、timestamp 等中繼資料

  Scenario: Error log 不包含完整的對話內容
    Given 系統發生錯誤（如解析失敗）
    When 輸出 ERROR log
    Then log 包含錯誤資訊和原始 JSON（用於除錯）
    And 但不包含從對話文本提取的敏感內容
    And 原始 JSON 用於開發者除錯，不在 production 中完整輸出（release 模式禁用 DEBUG）

  # 額外場景：Log 等級一致性驗證
  Scenario: Log 等級分佈遵循規範
    Given 系統運行一段時間
    When 收集所有 log 記錄
    Then DEBUG log（詳細執行記錄）遠多於其他等級
    And INFO log（重要里程碑）數量適中
    And WARN log（非預期但可繼續）數量少
    And ERROR log（需要關注的失敗）數量最少或無

  # 額外場景：多層 log 協調
  Scenario: 多層 log 形成完整的執行軌跡
    Given 新 session 檔案被建立
    When 系統完整處理此檔案直到 state 更新
    Then 整個過程被完整記錄：
      | 層級 | log 內容 |
      | File Watcher | 偵測到新檔案 |
      | File Watcher | 讀取新行 |
      | JSONL Parser | 解析事件 |
      | Session Manager | 狀態轉換（如有） |
      | WebSocket Server | 推送給訂閱者 |
      | Flutter Client | 接收訊息 |
      | Event Mapper | 映射事件 |
    And 整個軌跡可供除錯追蹤
