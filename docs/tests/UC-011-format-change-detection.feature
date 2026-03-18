Feature: UC-011 JSONL/事件格式變動偵測

  Background:
    Given Go Backend 已啟動並正在監控 JSONL 檔案
    And Flutter Frontend 已連接 WebSocket
    And 結構化日誌系統已初始化（UC-010）

  # --- Main Flow: Go Backend 未知 JSONL 欄位偵測 ---

  Scenario: Go JSONL Parser 偵測頂層未知欄位
    Given JSONL Parser 已定義已知頂層欄位列表
      | 已知欄位 |
      | type |
      | message |
      | timestamp |
    And JSONL 行包含未知的頂層欄位 "newFeatureFlag"
    When Parser 解析該行
    Then Parser 輸出 WARN log，包含：
      | 欄位 | 值 |
      | unknownField | newFeatureFlag |
      | sessionID | 來源 session 識別碼 |
      | hint | Claude format may have changed |
    And 已知欄位正常解析完成

  # --- Alt Flow A1: content array 未知元素類型 ---

  Scenario: Go JSONL Parser 偵測 content array 未知元素類型
    Given assistant message 的 content array 包含一個元素
    And 該元素的 type 為 "interactive_canvas"（不在已知列表）
    When Parser 解析 content array
    Then Parser 輸出 WARN log，包含：
      | 欄位 | 值 |
      | unknownElementType | interactive_canvas |
      | rawElement | 原始 JSON（截斷至 200 字元） |
      | hint | New content type may need support |
    And 該元素以 unknown 類型保留 raw JSON 繼續傳遞

  # --- Requirement: layer 欄位識別 ---

  Scenario: Go Backend WARN log 包含 layer 欄位便於快速識別
    Given JSONL 行包含未知欄位 "experimentalMode"
    When Parser 偵測到未知欄位並輸出 WARN log
    Then WARN log 包含 layer: "jsonl_parser"
    And 開發者可透過 layer 欄位快速定位需要更新的程式碼層級

  # --- Requirement: WARN 不中斷解析 ---

  Scenario: WARN 欄位偵測後解析流程繼續正常進行
    Given JSONL 行同時包含已知欄位和未知欄位 "newMetadata"
    When Parser 偵測到未知欄位並輸出 WARN log
    Then Parser 繼續解析已知欄位
    And 組裝為正常的 SessionEvent
    And 事件被推送到 event channel
    And 後續 JSONL 行繼續正常處理

  # --- Exception E1: log 去重 ---

  Scenario: 相同未知欄位多次出現時進行 log 去重
    Given 同一個未知欄位 "newFeatureFlag" 連續出現於 5 行 JSONL
    When Parser 逐行解析
    Then Parser 僅輸出 1 次 WARN log（去重機制）
    And 避免 log 爆炸影響可讀性
    And 所有 5 行的已知欄位仍正常解析

  # --- Alt Flow A2: Flutter 未知事件類型 ---

  Scenario: Flutter Event Mapper 偵測未知事件類型
    Given Flutter Event Mapper 已定義已知事件類型列表
    And WebSocket 收到一個事件，type 為 "agent_handoff"（不在已知列表）
    When Event Mapper 處理該事件
    Then Event Mapper 輸出 WARN log，包含：
      | 欄位 | 值 |
      | unknownType | agent_handoff |
      | rawData | 原始資料（截斷至 200 字元） |
      | hint | Backend event type may have changed |
      | layer | event_mapper |
    And 該事件不導致 Flutter 崩潰或例外

  # --- Alt Flow A3: Flutter 已知類型未知欄位 ---

  Scenario: Flutter Event Mapper 偵測已知事件類型的未知欄位
    Given WebSocket 收到 session_event 事件（已知類型）
    And 該事件包含未知欄位 "priority_level"
    When Event Mapper 處理該事件
    Then Event Mapper 輸出 WARN log，包含：
      | 欄位 | 值 |
      | eventType | session_event |
      | unknownField | priority_level |
      | hint | Backend event schema may have changed |
      | layer | event_mapper |
    And 已知欄位正常處理
    And 未知欄位被忽略

  # --- Requirement: 降級呈現 ---

  Scenario: Flutter UI 對未知事件進行降級呈現而不崩潰
    Given Flutter 收到未知類型的事件
    When Event Mapper 將其標記為未知事件
    Then UI 以「未知區塊」樣式呈現該事件
    And 不顯示空白或錯誤畫面
    And 應用程式繼續正常運行
    And 使用者可繼續操作其他功能

  # --- Integration: 端到端格式變動偵測 ---

  Scenario: 端到端格式變動偵測：Go Backend 到 Flutter Frontend
    Given Claude Code 更新後 JSONL 新增了未知頂層欄位 "modelVersion"
    When Go Backend 解析含有 "modelVersion" 的 JSONL 行
    Then Go Backend 輸出 WARN log（layer: "jsonl_parser"）
    And Go Backend 正常解析已知欄位並產生 SessionEvent
    When SessionEvent 透過 WebSocket 推送到 Flutter Frontend
    Then Flutter Frontend 正常接收並呈現已知欄位內容
    And 兩端的 WARN log 均可透過 "format may have changed" 關鍵字搜尋到

  # --- Integration: 開發者工作流程 ---

  Scenario: 模擬格式版本升級的開發者工作流程
    Given 系統運行中，Claude Code 版本升級導致格式變動
    And JSONL 新增未知欄位 "contextWindow" 和未知 content type "code_execution"
    When Go Backend 解析新格式的 JSONL
    Then 開發者查詢 WARN log（關鍵字: "format may have changed"）
    And 根據 layer 欄位定位：
      | layer | 行動 |
      | jsonl_parser | 更新 Go Parser 欄位解析邏輯 |
      | event_mapper | 更新 Flutter event 映射 |
    And WARN log 中的 hint 欄位文字一致，便於 grep 查詢
    And 所有 WARN log 的 hint 均包含 "may have changed" 關鍵字
