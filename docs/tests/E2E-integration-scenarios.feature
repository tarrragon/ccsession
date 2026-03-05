Feature: 端對端整合測試場景

  Background:
    Given Go Backend 已啟動，監聽 localhost:8765
    And Flutter Frontend 已啟動
    And ~/.claude/projects/ 目錄結構已準備
    And 至少存在 2 個活躍的 Claude Code session

  Scenario: Happy Path - 從啟動到實時監控的完整流程
    Given 初始狀態：Backend 和 Frontend 都未連線
    When Frontend 啟動
    Then Frontend 自動連線到 Backend WebSocket
    And Backend 推送完整的 session_list 訊息
    And Frontend 在 sidebar 顯示所有 session，按狀態分組
    When 用戶點擊某個 active session
    Then Frontend 發送 get_session_history 請求
    And Backend 回傳最近 100 條事件
    And Frontend 在主區域渲染完整對話
    When 該 session 產生新事件
    Then Backend 推送 session_event 訊息
    And Frontend 在 500ms 內渲染新事件
    And 對話自動捲動到最新訊息

  Scenario: 多 Session 並行監控
    Given Frontend 以 Split Horizontal 模式顯示 2 個 session
    And 左面板監控 session-A，右面板監控 session-B
    When session-A 產生新的 user message 事件
    Then 左面板即時渲染該訊息
    When 同時 session-B 產生新的 assistant response 事件
    Then 右面板同時即時渲染
    And 兩個面板的更新獨立進行，無衝突

  Scenario: Session 狀態轉換的視覺反饋
    Given Frontend 顯示多個 session
    And session-C 處於 active 狀態
    When session-C 超過 2 分鐘無新事件
    Then Backend 定期掃描，轉換狀態為 idle
    And Backend 推送 session_status_change 訊息
    And Frontend 以動畫（slide + fade, 300ms）將 session-C 從 Active 群組移至 Idle 群組
    When 5 分鐘後再有新事件
    Then Backend 轉換狀態為 active
    And Frontend 以高亮動畫將 session-C 重新移至 Active 群組頂部

  Scenario: 對話歷史分頁載入
    Given 某個 session 包含 500 條事件
    When Frontend 首次開啟該 session
    Then Backend 回傳最近 100 條事件
    And Frontend 顯示「載入更早的訊息」按鈕
    When 用戶點擊該按鈕
    Then Frontend 發送 get_session_history（limit=100, before=oldest_timestamp）
    And Backend 回傳之前的 100 條事件（timestamp 排序，無重複）
    And Frontend 將新事件 prepend 到對話頂部
    When 用戶繼續點擊，直到無更早事件
    Then Backend 回傳 < 100 條事件（表示已到頭）
    And Frontend 隱藏「載入更早的訊息」按鈕

  Scenario: 搜尋功能整合
    Given Frontend 顯示某個 session 的對話
    When 用戶按 Ctrl/Cmd+F 開啟搜尋
    Then 搜尋列出現
    When 用戶輸入「error」
    Then 所有包含「error」的訊息被高亮
    And 搜尋列顯示「3/15」（共 15 個匹配，目前第 3 個）
    When 用戶點擊下箭頭
    Then 焦點移動到第 4 個匹配
    And Frontend 自動捲動該位置
    And 搜尋列更新為「4/15」

  Scenario: 新 Session 動態出現
    Given Frontend 顯示 session 列表（2 個 active session）
    When 用戶在另一個 CLI 視窗開啟新的 Claude Code session
    Then Backend 偵測到新 JSONL 檔案（UC-006）
    And Backend 為新 session 建立元資料並註冊
    Then Backend 推送 session_status_change 訊息給 Frontend
    And Frontend 以 fade-in 動畫在 Active 群組頂部加入新 session
    And 用戶立即看到新 session 出現，無需重啟應用

  Scenario: JSONL 解析的子事件重組
    Given 某個 JSONL 行包含複雜 assistant 回應（text + tool_use + tool_result）
    When Backend 解析該行
    Then Backend 為三個內容元素產生三個子事件
    And 每個子事件含 messageId、contentIndex、isLastContent 識別欄位
    And 第一個子事件（text）的 isLastContent=false
    And 第二個子事件（tool_use）的 isLastContent=false
    And 第三個子事件（tool_result）的 isLastContent=true
    When Backend 推送這三個子事件
    Then Frontend 根據 messageId 和 contentIndex 分組
    And 當收到 isLastContent=true 時，標記為完整
    And Frontend 組裝成單個 assistant message，內含完整的 text、tool_use、tool_result

  Scenario: WebSocket 斷線與重連
    Given Frontend 與 Backend 連線正常
    And Frontend 訂閱了 session-A
    When 網路中斷（或 Backend 重啟）
    Then Frontend 偵測到連線中斷
    And Frontend 顯示「已斷線」（紅色圓點）
    Then Frontend 啟動重連（1s 後首次重試）
    When Backend 重新啟動並監聽
    Then Frontend 重連成功
    And Frontend 重新發送 subscribe_session（session-A）
    And Frontend 顯示「已連線」（綠色圓點）
    And Frontend 再次接收 session-A 的新事件

  Scenario: 效能指標達成 - 端到端延遲
    Given Backend 和 Frontend 連線正常
    When 新事件寫入 JSONL 檔案
    Then 開始計時
    And Backend file watcher 偵測（目標 <= 100ms）
    And Backend parser 解析（目標 <= 50ms）
    And Backend session manager 更新（目標 <= 20ms）
    And Backend WebSocket 推送（目標 <= 30ms）
    And Frontend 事件處理和 UI 渲染（目標 <= 200ms）
    When 事件在 Frontend UI 顯示
    Then 總端到端延遲 <= 400ms（上限 500ms）

  Scenario: 批量 Session 初始化
    Given 某個 project 目錄下存在 20 個既存 JSONL 檔案
    When Backend 首次掃描該目錄
    Then Backend 依 mtime 排序，逐一載入各檔案
    And 為每個檔案建立 session 元資料
    And Frontend 在 UI 中依次看到 session 被加入
    And 不因檔案數量多而導致應用卡頓或延遲

  Scenario: 大型 Session 處理
    Given 某個 session 的 JSONL 檔案包含 10000 行（超大對話）
    When Frontend 開啟該 session
    Then Backend 回傳最近 100 條事件（自動限制，預設 max_history_lines=1000）
    And Frontend 渲染 100 條事件，流暢無卡頓
    When 用戶分頁載入更早的 100 條事件
    Then Backend 正確回傳，無重複、無遺漏
    And 分頁載入無限制次數，記憶體使用穩定

  Scenario: 錯誤恢復與容錯
    Given JSONL 檔案包含某些格式不正確的行
    When Backend 掃描和解析該檔案
    Then Backend 跳過格式錯誤的行
    And 記錄 debug log
    And 正常解析其他行
    And Frontend 正常接收並顯示可解析的事件
    When 某個 session JSONL 檔案意外被刪除
    Then Backend 偵測到 Remove 事件
    And Backend 通知 Session Registry 該 session 已結束
    And Frontend 接收 session_status_change 訊息
    And Frontend 優雅降級，不顯示該 session 的實時更新（但歷史仍可查看）

  Scenario: 並行 4 個 Session 的完整流程
    Given Frontend 以 Grid 2x2 模式顯示 4 個不同的 session
    When 4 個 session 同時進行對話、tool calls、思考過程
    Then Backend 並行處理 4 個 JSONL 檔案的變更
    And Parser 並行解析 4 個檔案的新行
    And WebSocket 同時推送 4 個 session 的事件
    And Frontend 4 個面板同時即時更新
    And 無任何 session 因並行而被延遲或跳過

  Scenario: Metadata 來源優先級驗證
    Given 多個 session 具有不同的 metadata 完整度
    When Backend 初始化 session registry
    Then Session A（有 sessions-index.json）使用該檔案的 summary 和 gitBranch
    And Session B（無 sessions-index.json）使用 JSONL 第一個 user prompt 作為 summary
    And Session C（JSONL 為空）顯示「(unnamed session)」和「(unknown)」
    And 所有 session 都正確顯示，無遺漏或 null 值

  Scenario: 跨平台相容性驗證（macOS）
    Given Backend 運行在 macOS
    When fsnotify 使用 kqueue 監控檔案
    Then 檔案變更能正確被偵測
    And 性能表現達到預期（延遲 < 100ms）

  Scenario: 跨平台相容性驗證（Linux）
    Given Backend 運行在 Linux
    When fsnotify 使用 inotify 監控檔案
    Then 檔案變更能正確被偵測
    And 考慮 inotify watcher 數量限制（可配置）
    And 性能表現達到預期

  Scenario: 心跳機制防止僵屍連線
    Given Frontend 與 Backend WebSocket 連線已建立
    When 連線陷入無實際數據交換的狀態（但連線仍開啟）
    Then Backend 每 30 秒發送 ping
    And Frontend 自動回應 pong
    When Frontend 因異常（如系統休眠）無法回應
    Then Backend 連續等待 3 次 pong（90 秒）
    And 之後 Backend 主動斷開連線
    And Frontend 偵測到斷線，開始重連

  Scenario: 持久化狀態在應用重啟後恢復
    Given 用戶設置了 Grid 2x2 多 session 分割
    And 各面板分別綁定 session-A、session-B、session-C、session-D
    When 應用關閉
    Then layoutMode（grid2x2）和各 panels[].sessionId 被持久化
    When 應用重啟
    Then 自動恢復 Grid 2x2 佈局
    And 每個面板恢復其綁定的 session
    And 用戶看到與關閉前相同的佈局
