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
