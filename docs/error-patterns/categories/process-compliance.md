# 流程合規錯誤模式

## PC-001: 通用框架工具因 todolist 格式不一致造成版本偵測污染

**發現日期**: 2026-03-05
**相關 Ticket**: feat/fix-ticket-version-detection (commit eb94b91)

### 症狀

- `ticket track summary` 顯示其他專案的版本號（如 v0.31.0）
- 顯示的 ticket 不屬於當前專案
- ticket 內容幾乎空白（只有 frontmatter）

### 根因

`version.py` 的 `_parse_todolist_active_version()` 只支援一種 todolist.yaml 格式：

```yaml
# 只支援此格式（框架標準）
versions:
  - version: "0.31.0"
    status: active
```

當專案使用不同格式時：

```yaml
# 此格式不被識別（專案自訂）
status: active
current_version: 0.2.0
```

函式回傳 None，fallback 到掃描 `docs/work-logs/` 目錄，取最高版本號。若目錄中有其他專案誤放的 stray tickets（版本號更高），就會被誤用。

### 解決方案

在 `_parse_todolist_active_version()` 加入第二種格式的支援：

```python
# 格式二：current_version 頂層欄位（專案自訂格式）
current_version = data.get("current_version")
if current_version:
    version_str = str(current_version)
    if not version_str.startswith("v"):
        version_str = f"v{version_str}"
    return version_str
```

同時刪除 stray 的版本目錄。

### 預防措施

1. 通用框架工具設計時，應明確列出所支援的配置格式（不能只假設一種）
2. `get_project_root()` 的 `pubspec.yaml` 搜尋邏輯對 Go/混合型專案無效，應以 `CLAUDE_PROJECT_DIR` 為主要偵測機制
3. 新專案加入框架後，確認 `todolist.yaml` 使用框架標準的 `versions` 列表格式，或確保框架工具支援其格式
4. Fallback 掃描目錄的邏輯應加入警告 log，提示版本來自 fallback 而非明確配置
