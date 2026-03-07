# 程式碼品質錯誤模式

## CQ-001: 私有函式跨模組引用導致封裝破壞

**發現日期**: 2026-03-07
**相關 Ticket**: 0.1.0-W6-001, 0.1.1-W5-001

### 症狀

- 新模組（如 `handoff_gc.py`）直接 import 另一模組（如 `resume.py`）的 `_` 前綴私有函式
- 程式碼功能正常，但架構審查時發現封裝邊界問題
- 相同的輔助邏輯同時存在於兩個模組（DRY 問題）

### 根因

實作新功能時，發現現有模組中有需要的輔助函式，直接 import 了「最近的可用版本」。因為 Python 的 `_` 前綴只是慣例（非語法強制），跨模組引用語法上合法，但違反模組邊界設計意圖。

```python
# 問題：handoff_gc.py 引用 resume.py 的私有函式
from ticket_system.commands.resume import (
    _is_ticket_completed,        # _ 前綴表示模組私有
    _is_task_chain_direction,    # _ 前綴表示模組私有
    _is_ticket_in_progress_or_completed,  # _ 前綴表示模組私有
)
```

### 解決方案

將跨模組共用的輔助函式遷移至共用層（`lib/`）：

```python
# 正確：將共用函式移到 lib/handoff_utils.py
# ticket_system/lib/handoff_utils.py
def is_ticket_completed(ticket_id: str) -> bool:
    ...

def is_task_chain_direction(direction: str) -> bool:
    ...

# handoff_gc.py 和 resume.py 都從共用模組引用
from ticket_system.lib.handoff_utils import (
    is_ticket_completed,
    is_task_chain_direction,
    is_ticket_in_progress_or_completed,
)
```

### 預防措施

1. 新增模組時，若需要引用其他模組的私有函式，應先評估是否將其提升為共用函式
2. 程式碼審查時，檢查是否有 `from module import _function` 模式
3. 設計新功能模組時，先確認共用輔助邏輯的歸屬層（`lib/` vs `commands/`）

---

## CQ-002: Positional Argument 作為子命令偵測導致路由不一致

**發現日期**: 2026-03-07
**相關 Ticket**: 0.1.0-W6-001

### 症狀

- 新增子命令時，使用 positional argument 的值作為子命令判斷（如 `ticket_id == "gc"`）
- 現有子命令用 flag 路由（`--status`），新子命令用值路由（`ticket_id == "gc"`），行為不一致
- 若用戶 ticket ID 恰好為保留關鍵字，行為會被誤攔截

### 根因

快速整合 GC 命令時，沒有重構現有的 argparse 結構（新增嵌套 subparsers），而是選擇在 `execute()` 中用值判斷繞過：

```python
# 問題：以 positional argument 的值判斷子命令
def execute(args: argparse.Namespace) -> int:
    if getattr(args, "ticket_id", None) == "gc":  # ad-hoc 偵測
        from ticket_system.commands.handoff_gc import execute_gc
        return execute_gc(dry_run=not getattr(args, "execute", False))
```

### 解決方案

使用 argparse 的嵌套 subparsers 結構：

```python
def register(subparsers):
    parser = subparsers.add_parser("handoff", ...)
    handoff_subparsers = parser.add_subparsers(dest="handoff_action")

    # gc 子命令
    gc_parser = handoff_subparsers.add_parser("gc", ...)
    gc_parser.add_argument("--dry-run", action="store_true")
    gc_parser.add_argument("--execute", action="store_true")
    gc_parser.set_defaults(func=execute_gc_wrapper)

    # 主 handoff 命令
    main_parser = handoff_subparsers.add_parser("run", ...)  # 或保持現有結構
```

### 預防措施

1. 新增命令功能時，優先考慮使用 argparse subparsers 而非值判斷
2. 相同層級的路由邏輯應保持一致（都用 flag 或都用 subparser）
3. 保留字（`gc`, `status`, `help` 等）應列出清單並在文件中說明

---

## CQ-004: namedtuple/dataclass 早退路徑返回裸型別（AttributeError 潛在 Bug）

**發現日期**: 2026-03-07
**相關 Ticket**: 0.1.0-W7-004, 0.1.0-W8-001

### 症狀

- 函式宣告返回 `namedtuple`（如 `HandoffListResult`）
- 但函式中有早退路徑（early return）返回裸型別（如 `[]`）
- 呼叫端統一以 `result.field` 存取，特定條件（如目錄不存在）時引發 `AttributeError`
- 問題只在環境缺失（目錄不存在、資源不可用）時才觸發，一般測試難以發現

### 根因

重構函式返回型別時，開發者更新了主要路徑的返回值（namedtuple），但忘記同步更新早期保護性退出（如 `if not dir.exists(): return []`）。因為早退路徑通常簡短且邏輯明確，容易被遺漏。

```python
# 問題：函式宣告返回 HandoffListResult，但早退路徑返回 []
def list_pending_handoffs() -> HandoffListResult:
    pending_dir = _get_handoff_dir(HANDOFF_PENDING_SUBDIR)
    if not pending_dir.exists():
        return []  # Bug：型別與宣告不符，呼叫端 result.handoffs 引發 AttributeError
    ...
    return HandoffListResult(handoffs=..., stale_count=..., schema_error_count=...)
```

### 解決方案

所有退出路徑統一返回完整的 namedtuple：

```python
def list_pending_handoffs() -> HandoffListResult:
    pending_dir = _get_handoff_dir(HANDOFF_PENDING_SUBDIR)
    if not pending_dir.exists():
        return HandoffListResult(handoffs=[], stale_count=0, schema_error_count=0)  # 正確
    ...
    return HandoffListResult(handoffs=..., stale_count=..., schema_error_count=...)
```

### 預防措施

1. 重構函式返回型別後，搜尋函式內所有 `return` 語句，逐一確認型別一致性
2. 型別標注工具（mypy）可偵測此問題：`mypy --strict` 會報告型別不符的 `return` 語句
3. 新增測試案例：在目錄不存在的環境下呼叫函式，驗證返回值可用 `.field` 存取

---

## CQ-005: Mock 路徑未隨函式遷移同步更新

**發現日期**: 2026-03-07
**相關 Ticket**: 0.1.0-W7-001, 0.1.0-W8-001

### 症狀

- 執行測試時出現 `AttributeError: <module> does not have the attribute '_function_name'`
- `@patch("module.path._function_name")` 中的路徑找不到目標
- 測試在重構前正常，重構後（函式遷移/重命名）出現失敗
- 錯誤訊息明確指出缺少屬性，但初看像是模組載入問題

### 根因

W7-001 將 `resume.py` 中的私有函式 `_is_ticket_completed` 遷移至 `lib/handoff_utils.py` 並改名為公開函式 `is_ticket_completed`。`resume.py` 改以 `from handoff_utils import is_ticket_completed` 引入。

測試的 `@patch("ticket_system.commands.resume._is_ticket_completed")` 路徑未隨之更新：
- 名稱由 `_is_ticket_completed`（私有）改為 `is_ticket_completed`（公開）
- 正確的 patch 位置是函式使用端（`resume.is_ticket_completed`），不是定義端

```python
# 問題：patch 舊的私有名稱，但該名稱在遷移後不存在
@patch("ticket_system.commands.resume._is_ticket_completed")  # AttributeError

# 正確：patch 使用端的名稱（at point of use）
@patch("ticket_system.commands.resume.is_ticket_completed")   # 正確
```

### 解決方案

1. 確認函式在目標模組中的實際引入方式（`from X import Y`→ patch 使用端）
2. 更新 `@patch` 路徑為使用端模組 + 新名稱

### 預防措施

1. 函式遷移（特別是從私有升為公開）後，立即搜尋測試檔案中的相關 `@patch` 路徑
2. `grep -r "_old_function_name" tests/` 找出需要更新的路徑
3. 遷移 Ticket 的驗收條件中明確加入「更新相關測試 Mock 路徑」
4. CI 全量測試才能覆蓋此類問題，本地只跑被修改模組的測試容易遺漏

---

## CQ-003: Exception 定義後無實際拋出點（設計意圖未實現）

**發現日期**: 2026-03-07
**相關 Ticket**: 0.1.0-W5-001, 0.1.1-W5-003

### 症狀

- `exceptions.py` 中定義了 `HandoffDirectionUnknownError`
- 但 `resume.py`、`handoff.py`、`handoff_gc.py` 均未在讀取未知 direction 時拋出此 exception
- Exception 類別存在但從未被拋出（dead code）

### 根因

設計 Exception 階層時，超前定義了「未來可能需要」的 exception，但 Phase 3b 實作時只實作了當下需要的（Schema 驗證、目標存在性、重複 handoff），`HandoffDirectionUnknownError` 的實際觸發點未被實作。

這是 IMP-013「設計意圖未實現」模式的再現：新增了 API（exception 類別），但未實作對應的使用端。

```python
# exceptions.py 有定義
class HandoffDirectionUnknownError(HandoffError):
    """Handoff JSON 的 direction 值不在已知 enum 範圍內。"""
    ...

# 但 resume.py 的 list_pending_handoffs() 讀取 direction 時沒有驗證
direction = data.get("direction", "")  # 未知 direction 靜默略過，無任何驗證
```

### 解決方案

在 `resume.py` 的 `list_pending_handoffs()` 中讀取 direction 後加入驗證：

```python
KNOWN_DIRECTION_TYPES = frozenset({
    "context-refresh", "to-parent", "to-sibling", "to-child", "auto"
})

direction = data.get("direction", "")
direction_type = direction.split(":")[0]
if direction_type and direction_type not in KNOWN_DIRECTION_TYPES:
    raise HandoffDirectionUnknownError(direction, str(handoff_file))
```

### 預防措施

1. 定義 Exception 類別時，同步建立對應的觸發點（拋出 exception 的程式碼）
2. 若 exception 為「未來預留」，在類別 docstring 中明確標注
3. Phase 4 重構評估時，檢查是否有未使用的 exception 類別（IMP-013 模式）
4. 可以使用靜態分析工具或測試確認每個 exception 至少有一個測試路徑

---
