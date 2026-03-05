Feature: UC-004 多 Session 分割畫面

  Background:
    Given Flutter Frontend 已啟動
    And 至少存在 2 個 session
    And Session 對話檢視功能正常（UC-002）

  Scenario: 單一 session 全螢幕模式
    Given 應用啟動時預設為單一 session 模式
    When 用戶點擊某個 session
    Then 該 session 的對話佔滿主區域

  Scenario: 切換到左右分割模式
    Given 當前為單一 session 模式
    When 用戶選擇「分割模式」> 「左右分割」
    Then 主區域分割為左右兩個面板
    And 左面板顯示當前 session，右面板為空面板

  Scenario: 切換到上下分割模式
    Given 當前為單一 session 模式
    When 用戶選擇「分割模式」> 「上下分割」
    Then 主區域分割為上下兩個面板
    And 上面板顯示當前 session，下面板為空面板

  Scenario: 切換到四格模式（Grid 2x2）
    Given 當前為單一 session 模式
    When 用戶選擇「分割模式」> 「四格網格」
    Then 主區域分割為 2x2 四個面板
    And 四個面板均為空面板（或顯示最後選中的 session）

  Scenario: 在每個面板獨立選擇 session
    Given 主區域已分割為多個面板
    When 用戶點擊左面板，選擇 session-A
    Then 左面板開始顯示 session-A 的對話
    When 用戶點擊右面板，選擇 session-B
    Then 右面板開始顯示 session-B 的對話
    And 兩個面板獨立運行 UC-002 和 UC-003 的邏輯

  Scenario: 所有面板同時即時更新
    Given 多個面板分別監控不同的 session
    When 多個 session 同時有新事件
    Then 每個面板的對話內容同時即時更新
    And 無延遲或不同步現象

  Scenario: 從 Sidebar 拖拉 session 到面板
    Given 多 session 分割模式已啟用
    And Sidebar 顯示 session 列表
    When 用戶長按 Sidebar 中的某個 session
    Then 該 session 項目進入拖拉狀態（視覺提示）
    When 用戶拖拉到某個空面板
    Then 該面板開始顯示該 session 的對話

  Scenario: 面板大小拖拉調整
    Given 多個面板分割顯示
    When 用戶拖拉面板間的分隔線
    Then 分隔線實時移動，面板大小即時調整
    And 對話內容自適應新寬度，正常排版
    And 調整過程流暢，無卡頓

  Scenario: 面板最大化
    Given 分割模式下有多個面板
    When 用戶雙擊某面板的標題列
    Then 該面板最大化，填滿整個主區域
    And 其他面板暫時隱藏
    And 分割模式暫存（未改變）

  Scenario: 面板還原
    Given 某面板處於最大化狀態
    When 用戶再次雙擊該面板的標題列
    Then 面板還原為分割佈局
    And 所有面板恢復可見
    And 各面板綁定的 session 不變

  Scenario: 關閉面板
    Given 多個面板分割顯示
    When 用戶點擊某面板的關閉按鈕
    Then 該面板關閉
    And 剩餘面板自動填滿空間
    When 只剩一個面板時
    Then 自動回到單一 session 檢視模式
    And 剩餘面板的 session 繼續顯示

  Scenario: 分割模式（layoutMode）持久化
    Given 用戶設置多 session 分割模式
    When 應用關閉
    Then 分割模式配置被儲存到本地
    When 應用重啟
    Then layoutMode 恢復為關閉前的配置（如 splitHorizontal, grid2x2 等）

  Scenario: 各面板的 sessionId 持久化
    Given 各面板分別綁定不同的 session
    When 應用關閉
    Then 每個面板綁定的 sessionId 被儲存到本地
    When 應用重啟
    Then 每個面板恢復其綁定的 session
    And 用戶看到與關閉前相同的佈局

  Scenario: 持久化 sessionId 對應的 session 不存在
    Given 持久化資料中記錄的 sessionId 對應的 session 已被刪除
    When 應用重啟
    Then 該面板恢復為空面板（sessionId 設為 null）
    And 用戶可重新選擇 session 綁定到該面板
    And 應用優雅降級，不崩潰

  Scenario: 持久化檔案不存在或損壞
    Given 持久化檔案丟失或內容損壞
    When 應用啟動
    Then 應用偵測到無效配置
    And 回退到預設狀態：layoutMode = single，面板為空
    And 應用正常啟動，無錯誤

  Scenario: 持久化面板數與 layoutMode 不一致
    Given 持久化資料中 layoutMode 指定 Grid 2x2（4 面板）
    But panels 清單只有 2 個面板
    When 應用啟動
    Then 以 layoutMode 為準，補充缺失面板為空
    And 多餘面板被捨棄

  Scenario: Phase 1 持久化範圍（最小可用）
    Given Phase 1 實作中
    When 應用執行多 session 分割
    Then layoutMode（分割模式）被持久化
    And 各 panels[].sessionId（面板綁定的 session）被持久化
    And scrollPosition（捲動位置）暫不持久化（Phase 4 功能）

  Scenario: Phase 4 持久化範圍擴充
    Given Phase 4 實作中
    When 應用執行多 session 分割並調整捲動位置
    Then layoutMode 被持久化
    And panels[].sessionId 被持久化
    And panels[].scrollPosition（捲動位置）被持久化
    And 面板自訂大小比例被持久化
    And 最大化面板狀態被持久化

  Scenario: 並行顯示 4 個不同 session 的即時更新
    Given 應用以 Grid 2x2 模式顯示 4 個不同的 session
    When 4 個 session 同時有新事件
    Then 每個面板的對話同時即時更新
    And 4 個面板各自獨立運行 UC-002、UC-003 邏輯
    And 無任何 session 因並行而被延遲或跳過
