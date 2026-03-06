Feature: UC-002 Session 對話檢視

  Background:
    Given Session 列表已載入（UC-001 完成）
    And 目標 session 的 JSONL 檔案存在且可讀取
    And WebSocket 連線正常

  Scenario: 點擊 session 後顯示完整對話
    Given Frontend 顯示 session 列表
    When 用戶點擊某個 session
    Then Frontend 發送 get_session_history 請求到 Backend
    And Backend 讀取該 session 的 JSONL 檔案
    And Backend 回傳 session_history 訊息（預設最近 100 條事件）
    And Frontend 在 1 秒內開始在主區域渲染對話內容

  Scenario: 各類事件正確區分顯示
    Given Backend 回傳包含多種事件類型的 session_history
    When Frontend 渲染對話內容
    Then User message 靠右對齊，藍色系背景
    And Assistant text 靠左對齊，灰色系背景，支援 Markdown 渲染
    And Tool use 顯示為可摺疊區塊，標題為 tool name + 簡要參數
    And Tool result 顯示為可摺疊區塊，程式碼風格背景
    And Thinking 顯示為可摺疊區塊，斜體樣式

  Scenario: Assistant 回應支援 Markdown 渲染
    Given Assistant 回應包含 Markdown 語法（標題、粗體、程式碼區塊等）
    When Frontend 渲染該回應
    Then 標題（# ## ### 等）正確格式化
    And 粗體（**text**）和斜體（*text*）正確格式化
    And 程式碼區塊（```）正確渲染為程式碼框
    And 清單（- 或 1. 等）正確縮排顯示
    And 連結（[text](url)）正確解析並可點擊

  Scenario: Tool use 區塊可摺疊展開
    Given 對話中存在 tool use 事件
    When 用戶點擊 tool use 區塊
    Then 區塊展開，顯示完整的 tool name 和 tool input 參數
    And 參數以 JSON 格式或可讀格式呈現
    When 用戶再次點擊
    Then 區塊摺疊回摘要狀態

  Scenario: 大型 session 支援分頁載入
    Given 某 session 包含超過 100 條事件
    When Frontend 初次載入
    Then Backend 回傳最近 100 條事件（limit=100）
    And Frontend 頂部顯示「載入更早的訊息」按鈕
    And 其他事件仍在記憶體中（Backend 可保留最多 1000 條，max_history_lines）
    When 用戶點擊「載入更早的訊息」
    Then Frontend 使用已載入最早事件的 timestamp 作為 before 參數
    And Frontend 發送 get_session_history(sessionId, limit=100, before=earliest_timestamp)
    And Backend 回傳此 timestamp 之前的 100 條事件（排他比較）
    And Frontend 將新事件 prepend 到對話頂部
    And 用戶閱讀位置不受影響，繼續閱讀

  Scenario: 分頁載入無重複和遺漏
    Given Frontend 已載入第一頁（時間戳 T1 ~ T2）
    When Frontend 載入第二頁（時間戳 T2 之前）
    Then Backend 返回的事件不包含時間戳 T2（排他比較）
    And 若同一 timestamp 下有多筆事件，Backend 必須在同一批次全部回傳
    And Frontend 分頁間無重複和遺漏，事件序列連續

  Scenario: 分頁載入結束信號
    Given Frontend 正在分頁載入歷史
    When Backend 回傳事件數量 < limit（如 50 < 100）
    Then Frontend 判定已無更早的歷史記錄
    And Frontend 隱藏「載入更早的訊息」按鈕

  Scenario: Active session 即時更新新事件
    Given Frontend 正在檢視某個 active session
    When Backend 推送 session_event 訊息（新事件）
    Then Frontend 將新事件 append 到對話底部
    And 新事件立即出現（延遲目標 < 500ms）

  Scenario: 自動捲動邏輯
    Given Frontend 顯示對話內容
    When 用戶在對話底部，新事件到達
    Then Frontend 自動捲動到最新事件
    When 用戶手動上捲，已不在底部
    Then Frontend 停止自動捲動
    And 底部出現「跳到最新」按鈕

  Scenario: 使用者點擊跳到最新
    Given Frontend 正在頂部載入歷史，new event 持續到達
    When 用戶點擊「跳到最新」按鈕
    Then Frontend 立即捲動到底部
    And 任何進行中的分頁載入請求被中止
    And 自動捲動恢復為啟用狀態

  Scenario: 自動捲動與分頁載入的優先級
    Given Frontend 正在頂部載入歷史（分頁進行中）
    When 同時收到新事件
    Then 新事件 append 到底部，不自動捲動
    And 分頁載入不被中斷（不跳躍到最新）
    And 用戶明確意圖（如點擊「跳到最新」）優先於系統自動行為

  Scenario: 事件排序（時間戳升序）
    Given Backend 回傳多個事件
    When Frontend 渲染對話
    Then 所有事件以 timestamp 升序排列（最早在上，最新在下）

  Scenario: 事件排序（同時間戳時的次級排序）
    Given 多筆事件具有相同 timestamp
    When Frontend 接收這些事件
    Then 事件按 JSONL 檔案中的行號順序排列（append 順序）
    And tool_use 必須出現在對應 tool_result 之前
    And thinking 必須出現在同一回合的 assistant 之前

  Scenario: Session 檔案不存在時優雅處理
    Given Backend 嘗試讀取不存在的 session JSONL 檔案
    When Frontend 請求該 session 的歷史
    Then Backend 回傳 error 訊息
    And Frontend 顯示友善提示：「此 session 的對話記錄已不存在」

  Scenario: JSONL 解析失敗時跳過錯誤行
    Given 某些 JSONL 行格式不正確或解析失敗
    When Backend 處理該檔案
    Then Backend 跳過失敗行，不中斷
    And Backend 正常回傳其他可解析的事件
    And Frontend 正常渲染已解析的事件

  Scenario: 連續快速事件不遺漏
    Given Agent 快速連續產生多個事件（如連續 tool calls）
    When Backend 推送這些事件
    Then Frontend 依序渲染所有事件，無遺漏
    And 事件順序與原始 JSONL 順序一致
