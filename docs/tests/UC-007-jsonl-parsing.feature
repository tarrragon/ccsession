Feature: UC-007 JSONL 事件解析

  Background:
    Given UC-006 已偵測到檔案變更並傳送原始行
    And Parser 準備好接收 JSONL 行

  Scenario: 正確解析 user message 事件
    Given JSONL 行包含 user message 事件
    When Parser 接收該行
    Then Parser 提取 type='user'、timestamp、message.content（string）
    And 組裝為 SessionEvent
    And 事件被推送到 event channel

  Scenario: 正確解析 assistant text 回應
    Given JSONL 行包含 assistant message，content 為文字
    When Parser 接收該行
    Then Parser 提取 type='assistant_text'、timestamp、content.text
    And 組裝為 SessionEvent

  Scenario: 正確解析 tool_use 事件
    Given JSONL 行包含 assistant message，content 中含 tool_use 元素
    When Parser 接收該行
    Then Parser 提取 type='tool_use'、tool name、tool input（參數）
    And 組裝為 SessionEvent（含 toolName 欄位）

  Scenario: 正確解析 tool_result 事件
    Given JSONL 行包含 tool_result 訊息
    When Parser 接收該行
    Then Parser 提取 type='tool_result'、content（執行結果）
    And 組裝為 SessionEvent

  Scenario: 正確解析 thinking 事件
    Given JSONL 行包含 assistant message，content 中含 thinking 元素
    When Parser 接收該行
    Then Parser 提取 type='thinking'、thinking 文字
    And 組裝為 SessionEvent

  Scenario: 巢狀 content array 的子事件拆分
    Given JSONL 行包含 assistant message，message.content 包含多個元素（text + tool_use + tool_result）
    When Parser 接收該行
    Then Parser 為每個元素產生一個子事件
    And 保持原始順序
    And 每個子事件包含：
      | 欄位 | 值 |
      | messageId | 原始 message 識別碼 |
      | contentIndex | 元素在 array 中的索引（0-based） |
      | isLastContent | 是否為最後一個子事件 |

  Scenario: isLastContent 信號設置正確
    Given assistant content array 包含 4 個元素
    When Parser 為每個元素產生子事件
    Then 前 3 個子事件的 isLastContent = false
    And 第 4 個子事件的 isLastContent = true
    And Backend 在推送最後一個子事件時設置此信號

  Scenario: 子事件發送順序與 content array 一致
    Given content array 的順序為：[text, tool_use, tool_result, thinking]
    When Parser 推送子事件
    Then 子事件發送順序為：text(contentIndex=0), tool_use(contentIndex=1), tool_result(contentIndex=2), thinking(contentIndex=3)
    And Frontend 根據 contentIndex 正確組裝

  Scenario: 未知事件類型的容錯處理
    Given JSONL 行包含未知的 type 值（如 type='future_event'）
    When Parser 接收該行
    Then Parser 以 generic 方式處理
    And 保留 raw JSON
    And 輸出 WARN log（含 unknownType='future_event'、hint='Claude format may have changed'）
    And 事件繼續處理，不中斷流程

  Scenario: JSON parse 失敗時忽略不完整行
    Given JSONL 行內容不是有效的 JSON（寫入中途被讀取）
    When Parser 嘗試 parse
    Then JSON parse 失敗
    And Parser 忽略該行，無異常拋出
    And 記錄 debug 日誌
    And 後續行正常處理

  Scenario: 缺少必要欄位的優雅降級
    Given JSONL 行缺少 type 或 timestamp 欄位
    When Parser 接收該行
    Then Parser 盡可能填入預設值（如當前時間作為 timestamp）
    When 無法補救
    Then Parser 跳過該行

  Scenario: 非預期的 content 格式處理
    Given JSONL 行的 content 既不是 string 也不是 array
    When Parser 接收該行
    Then Parser 嘗試 toString() 處理
    And 記錄 warning 日誌
    And 繼續處理

  Scenario: 不完整 JSON 行的下次重試
    Given 第一次讀取時某行不完整
    When 該行再次被讀取（下次檔案變更時）
    Then Parser 重新嘗試解析
    When 該行現在完整
    Then 解析成功，事件正常產出

  Scenario: 子事件前端重組規則
    Given Backend 推送多個子事件
    When Frontend 接收子事件
    Then Frontend 根據 messageId 分組
    And 同一 messageId 的子事件按 contentIndex 排序
    When 收到 isLastContent=true
    Then Frontend 標記該 message group 為完整
    And 執行最終呈現

  Scenario: 子事件邊界信號缺失時的降級
    Given Backend 未能設置 isLastContent 信號（異常情況）
    When Frontend 收到多個相同 messageId 的子事件
    Then Frontend 使用超時機制（如 300ms）判定邊界
    And 在超時後合併和呈現該 message

  Scenario: 單一 user message 無需拆分
    Given JSONL 行為 user message，message.content 為簡單 string
    When Parser 處理
    Then Parser 產出單一 SessionEvent
    And contentIndex = -1（表示非 assistant content array）
    And isLastContent = false（user message 不適用此欄位）

  Scenario: 支援的事件類型矩陣覆蓋
    Given JSONL 含所有已知事件類型
    When Parser 逐行處理
    Then 每種類型都正確映射為對應的 SessionEvent type
    And 關鍵欄位提取完整

  Scenario: Parser 效能指標
    Given 單行 JSONL 輸入
    When Parser 處理
    Then JSONL Parser 層耗時 <= 50ms
    And 支援吞吐量 >= 100 events/sec
