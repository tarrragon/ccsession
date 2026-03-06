Feature: UC-005 搜尋與篩選

  Background:
    Given Session 列表已載入（UC-001）
    And 至少存在一個包含對話歷史的 session

  Scenario: Session 列表即時篩選
    Given Frontend 顯示完整 session 列表（多個 session）
    When 用戶在 sidebar 搜尋欄輸入「my-project」
    Then 列表即時篩選，只顯示摘要、專案名稱或 Git branch 包含「my-project」的 session
    When 用戶清除搜尋文字
    Then 完整列表恢復顯示

  Scenario: 搜尋依據多個欄位
    Given Session 列表包含多個 session
    When 用戶輸入搜尋文字
    Then 搜尋依據以下欄位：
      | 欄位 | 說明 |
      | 摘要 | Session 摘要文字 |
      | 專案名稱 | Project path 最後一段 |
      | Git branch | Git branch 名稱 |
    And 任何欄位包含搜尋文字的 session 都顯示

  Scenario: 對話內容全文搜尋（前端已載入內容）
    Given Frontend 正在檢視某個 session 的對話
    When 用戶按下搜尋快捷鍵（Ctrl/Cmd + F）
    Then 搜尋列出現在對話檢視區域
    When 用戶輸入搜尋文字
    Then 所有符合的文字高亮顯示
    And 搜尋列右側顯示匹配計數，格式為「目前位置/總匹配數」（例如「3/15」）

  Scenario: 搜尋計數顯示規則
    Given 用戶搜尋對話內容
    When 有 15 個匹配結果，目前焦點在第 3 個
    Then 搜尋列顯示「3/15」
    When 無任何匹配
    Then 搜尋列顯示「0/0」
    When 搜尋欄為空（用戶未輸入）
    Then 搜尋列不顯示計數

  Scenario: 搜尋結果導航（上/下箭頭）
    Given 搜尋有多個匹配結果
    When 用戶點擊搜尋列的下箭頭
    Then 焦點移動到下一個匹配位置
    And 計數中的「目前位置」同步更新（如「4/15」）
    And Frontend 自動捲動到該匹配位置
    When 用戶點擊上箭頭
    Then 焦點移動到上一個匹配位置

  Scenario: 搜尋範圍限於已載入內容
    Given Session 包含 1000 條事件，但 Frontend 只載入了最近 100 條
    When 用戶搜尋對話
    Then 搜尋只限於已載入的 100 條事件
    And 不搜尋更早的未載入內容
    When 用戶透過「載入更早的訊息」擴展對話範圍
    Then 搜尋範圍也隨之擴展

  Scenario: 搜尋對話快捷鍵
    Given Frontend 正在檢視對話
    When 用戶按下 Ctrl+F（Windows/Linux）或 Cmd+F（macOS）
    Then 搜尋列出現
    When 用戶按下 Escape
    Then 搜尋列關閉，焦點回到對話

  Scenario: 搜尋回應時間
    Given Frontend 已載入 100 條事件的對話
    When 用戶輸入搜尋文字
    Then 搜尋結果在 < 200ms 內顯示
    And 高亮和計數同時出現

  Scenario: 搜尋不影響即時事件串流
    Given Frontend 正在搜尋對話
    When 新事件同時到達
    Then 新事件 append 到對話底部
    And 搜尋結果繼續正常高亮
    And 新事件的匹配文字也納入搜尋計數

  Scenario: 狀態群組展開/摺疊
    Given Frontend 顯示 session 列表，按狀態（Active / Idle / Completed）分組
    When 用戶點擊狀態群組標題（如「Active」）
    Then 該群組展開或摺疊
    And 其他群組狀態不變

  Scenario: 狀態篩選按鈕（可選）
    Given Session 列表顯示多個狀態的 session
    When 用戶使用篩選按鈕只顯示「Active」session
    Then 列表僅顯示 active 狀態的 session
    When 用戶選擇「Idle」篩選
    Then 列表切換為只顯示 idle session

  Scenario: 搜尋和篩選的組合
    Given Frontend 顯示 session 列表
    When 用戶同時應用搜尋和狀態篩選
    Then 列表結果同時滿足搜尋條件和狀態篩選條件

  Scenario: Phase 3+ 後端全文搜尋（預留設計）
    Given Phase 3+ 實作
    When 對話搜尋結果中提供「搜尋完整歷史」選項
    Then 用戶勾選後，Frontend 將搜尋請求發送至 Backend（預留 search_session action）
    And Backend 讀取完整 JSONL 檔案執行全文比對
    And Backend 回傳 search_results 訊息（預留），含匹配片段及位置高亮

  Scenario: 搜尋結果高亮視覺效果
    Given 搜尋有匹配結果
    When 搜尋結果被高亮顯示
    Then 匹配文字使用明顯的對比色（如黃色背景 + 深色文字）
    And 當前焦點的匹配結果高亮色更深（區別於其他結果）
    And 高亮效果清晰易辨
