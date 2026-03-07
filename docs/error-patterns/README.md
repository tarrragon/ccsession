# 錯誤模式知識庫

## 統計

| 類別 | 數量 |
|------|------|
| 流程合規 (PC) | 4 |
| 程式碼品質 (CQ) | 3 |
| **總計** | **7** |

## 索引

### 程式碼品質 (CQ)

- [CQ-001](./categories/code-quality.md#cq-001-私有函式跨模組引用導致封裝破壞) 私有函式跨模組引用導致封裝破壞
- [CQ-002](./categories/code-quality.md#cq-002-positional-argument-作為子命令偵測導致路由不一致) Positional Argument 作為子命令偵測導致路由不一致
- [CQ-003](./categories/code-quality.md#cq-003-exception-定義後無實際拋出點設計意圖未實現) Exception 定義後無實際拋出點（設計意圖未實現）

### 流程合規 (PC)

- [PC-001](./categories/process-compliance.md#pc-001-通用框架工具因-todolist-格式不一致造成版本偵測污染) 通用框架工具因 todolist 格式不一致造成版本偵測污染
- [PC-002](./categories/process-compliance.md#pc-002-get_project_root-因-pubspecyaml-搜尋策略在-go混合型專案中靜默失效) get_project_root() 因 pubspec.yaml 搜尋策略在 Go/混合型專案中靜默失效
- [PC-003](./categories/process-compliance.md#pc-003-cli-失敗時基於假設歸因而非調查實際語法) CLI 失敗時基於假設歸因而非調查實際語法
- [PC-004](./categories/process-compliance.md#pc-004-任務鏈-handoff-過濾只判斷來源-ticket-狀態未判斷目標-ticket-是否已啟動) 任務鏈 handoff 過濾只判斷來源 ticket 狀態，未判斷目標 ticket 是否已啟動

---

*最後更新: 2026-03-07*
