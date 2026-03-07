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

### 架構設計原則（根本問題）

> 通用框架 sync（sync-push/sync-pull）**不應**攜帶任何專案特定資料。
> 版本號屬於專案特定資料，不屬於框架本身。

**正確的框架/專案邊界**：

| 資料類型 | 屬於 | 應 sync |
|---------|------|--------|
| `.claude/hooks/`, `.claude/skills/`, `.claude/rules/` | 框架 | 是 |
| `docs/work-logs/`, `docs/todolist.yaml` | 專案 | 否 |
| `.claude/` 下任何含版本號的 hardcode | 框架（但不當） | 需移除 |

**設計要求**：
- `sync-push.sh` 應明確排除 `docs/` 目錄（或任何含版本號的專案資料）
- 框架工具（如 ticket CLI）讀取版本時，應依賴執行環境（`CLAUDE_PROJECT_DIR`/cwd）而非框架內的 hardcode
- 若框架必須有預設值，應用佔位符（如 `{current_version}`）而非具體版本號

---

## PC-002: get_project_root() 因 pubspec.yaml 搜尋策略在 Go/混合型專案中靜默失效

**發現日期**: 2026-03-05
**相關 Ticket**: 0.2.0-W4-001.1 (commit 3e59189)

### 症狀

- `ticket create` 將 Ticket 建立在 `.claude/skills/ticket/docs/` 目錄而非專案的 `docs/work-logs/`
- Ticket 系統行為正常（無報錯），但產出物位置錯誤
- 修正前首次執行才會發現問題（靜默失效，無任何警告）

### 根因

`paths.py` 的 `get_project_root()` 只向上搜尋 `pubspec.yaml`：

```python
# 舊實作：只搜尋 pubspec.yaml
current = Path.cwd()
while current != current.parent:
    if (current / "pubspec.yaml").exists():
        return current
    current = current.parent

return Path.cwd()  # fallback：回傳當前目錄
```

在 Go/混合型專案（如 ccsession）中，`pubspec.yaml` 位於 `ui/` 子目錄，不在專案根目錄。搜尋從 `.claude/skills/ticket/` 向上走到 `/`，找不到 `pubspec.yaml`，fallback 回傳 `Path.cwd()`（即 `.claude/skills/ticket/`）。

**靜默失效特性**：函式不拋出例外，也不輸出警告，讓使用方無法察覺路徑已錯誤。

### 解決方案

調整搜尋標記優先級，以 `CLAUDE.md`（所有使用 Claude Code 框架的專案都有）為主要指標：

```python
# 新實作：依序搜尋通用標記
markers = ["CLAUDE.md", "go.mod", "pubspec.yaml"]
current = Path.cwd()
while current != current.parent:
    for marker in markers:
        if (current / marker).exists():
            return current
    current = current.parent

return Path.cwd()
```

### 預防措施

1. 框架工具的「根目錄偵測」**不應假設特定語言的專案結構**（如 `pubspec.yaml` 是 Flutter 專有）
2. 根目錄偵測失敗時**必須輸出警告**，不可靜默返回 `Path.cwd()`
3. 新增語言支援（Go、Python 等）時，應同步更新 `get_project_root()` 的搜尋標記清單
4. 框架設計原則：優先使用**通用標記**（`CLAUDE.md`、`CLAUDE_PROJECT_DIR`），語言特定標記作為 fallback

### 根本問題

> `get_project_root()` 的搜尋策略是**語言耦合**的設計缺陷。
> 通用框架工具不應依賴特定語言的專案標記（`pubspec.yaml`）來定位專案根目錄。
> 正確設計應以**框架本身的標記**（`CLAUDE.md`）作為第一優先。

---

## PC-003: CLI 失敗時基於假設歸因而非調查實際語法

**發現日期**: 2026-03-05
**相關 Ticket**: 0.1.0-W2-003 建立過程中的 handoff 失敗

### 症狀

- `ticket handoff --to-sibling 0.1.0-W2-003` 回傳「目前沒有已完成的任務可供交接」
- PM 未調查 CLI 實際語法要求，直接假設原因為「PM 未認領 ticket，因此 CLI 找不到已完成的來源 ticket」
- 基於錯誤假設嘗試繞過（改用手動建立 handoff 檔案），偏離標準流程

### 根因

PM 在 CLI 報錯時，依賴「聽起來合理」的假設歸因，而非調查 CLI 的實際命令語法和參數要求。

**實際問題**：`ticket handoff` 需要指定已完成的來源 ticket 作為位置參數：

```bash
# 正確語法：指定來源 ticket
ticket handoff 0.1.0-W1-002 --to-sibling 0.1.0-W2-003

# 錯誤語法：缺少來源 ticket
ticket handoff --to-sibling 0.1.0-W2-003
```

**錯誤推理鏈**：

```
CLI 報「找不到已完成的任務」
    → PM 假設：因為 PM 沒有認領 ticket，所以找不到
    → 嘗試繞過：手動建立 handoff 檔案
    → 實際原因：缺少位置參數（來源 ticket ID）
```

### 解決方案

CLI 失敗時的正確調查流程：

1. **先查 CLI help**：`ticket handoff --help` 確認完整語法
2. **檢查錯誤訊息的字面意義**：「找不到已完成的任務」→ CLI 在搜尋哪裡？搜尋條件是什麼？
3. **對照實際狀態**：確認 W1-002 已 completed → 問題不在狀態，在語法
4. **最後才假設原因**：排除語法和參數問題後，再考慮邏輯層原因

### 預防措施

1. **CLI 失敗時禁止假設歸因**：必須先執行 `--help` 或查閱 SKILL.md 確認語法
2. **錯誤訊息優先字面解讀**：不要跳過訊息本身的含義去推測更深層原因
3. **繞過是最後手段**：在確認 CLI 本身有 bug 之前，不應繞過標準工具流程
4. **認知偏誤警覺**：「聽起來合理」不等於「是正確的」——合理性檢查需要證據

### 行為模式分析

此錯誤屬於「確認偏誤」(Confirmation Bias) 模式：

| 階段 | 錯誤行為 | 正確行為 |
|------|---------|---------|
| 觀察 | CLI 報錯 | CLI 報錯 |
| 假設 | 跳到「認領問題」假設 | 先查 `--help` 確認語法 |
| 驗證 | 未驗證假設，直接行動 | 驗證：W1-002 已 completed，排除狀態問題 |
| 行動 | 繞過標準流程 | 修正命令語法後重試 |

> **核心教訓**：工具失敗時，先調查工具的使用方式是否正確，再懷疑工具的邏輯。

---

## PC-004: 任務鏈 handoff 過濾只判斷來源 ticket 狀態，未判斷目標 ticket 是否已啟動

**發現日期**: 2026-03-07
**相關 Ticket**: 0.1.0-W3-011

### 症狀

- `ticket resume --list` 持續顯示已過時的 handoff（stale handoff）
- 來源 ticket（如 W3-008）已 completed，交接到目標 ticket（如 W3-009）
- 目標 ticket W3-009 也已 completed，但 W3-008 的 handoff JSON 仍出現在待恢復清單
- 用戶每次 session 啟動都需要手動忽略這些誤導性條目

### 根因

`list_pending_handoffs()` 的任務鏈過濾邏輯只做了**單側狀態檢查**：

```python
# 舊邏輯（不完整）
if _is_task_chain_direction(direction):
    handoffs.append(data)  # 無條件保留 → Bug
    continue
```

當 direction 為 `to-sibling:0.1.0-W3-009` 時，只確認「這是任務鏈 handoff」（來源側），但沒有確認**目標 ticket 是否已被接手**（目標側）。

**根本原因**：過濾設計只有「來源視角」，缺乏「目標視角」。任務鏈 handoff 在兩種情況下應保留：
- 目標 ticket 尚未啟動（pending）→ 仍需恢復
- 目標 ticket 已啟動（in_progress/completed）→ 已過時，應過濾

### 解決方案

新增 `_is_ticket_in_progress_or_completed()` 輔助函式，在任務鏈判斷後提取 `target_id` 並檢查目標狀態：

```python
if _is_task_chain_direction(direction):
    direction_parts = direction.split(":", 1)
    if len(direction_parts) > 1:
        target_id = direction_parts[1]
        if target_id and _is_ticket_in_progress_or_completed(target_id):
            continue  # 目標已啟動，此 handoff 為 stale
    handoffs.append(data)
    continue
```

**保守策略**：若 target_id 不存在或無法載入 → 保留（不過濾），避免誤刪有效 handoff。

### 預防措施

1. **雙側狀態設計原則**：設計任何「關係型過濾邏輯」（A → B 的關係）時，必須同時考慮 A 的狀態和 B 的狀態
2. **欄位格式溯源**：讀取 `direction` 欄位前先確認生產者的完整格式（可能含後綴 `:target_id`）
3. **測試覆蓋目標側**：任務鏈相關測試必須包含目標 ticket 已啟動 / 未啟動兩種情境

### 行為模式分析

此錯誤屬於「單側假設」模式：

| 維度 | 舊邏輯 | 正確邏輯 |
|------|--------|---------|
| 來源側 | 已 completed → 任務鏈，保留 | 已 completed → 進入任務鏈判斷 |
| 目標側 | 未考慮 | 目標已啟動 → stale；目標未啟動 → 保留 |
| 預設行為 | 保留（可能誤報） | 保守保留（無法判斷時顯示） |

> **核心教訓**：過濾「A 指向 B 的關係」時，A 的狀態和 B 的狀態都需要納入判斷；只檢查一側會產生假陽性。

---

## PC-005: 技術債/改善 ticket 版本歸屬錯誤（放入下一版本而非當前版本）

**發現日期**: 2026-03-07
**相關 Ticket**: 0.1.0-W7-001~004（從 0.1.1-W5-001~004 遷移）

### 症狀

- Phase 4 或多視角審查產生的技術債/改善 ticket 被建立在下一版本（如 v0.1.1）
- 造成當前版本（v0.1.0）看似「已完成」，但實際上有未追蹤的後續改善工作
- 需要事後執行 `ticket migrate` 批量遷移，造成不必要的操作成本

### 根因

建立技術債 ticket 時，使用了「當前活躍版本」（`ticket create` 的預設版本）而非思考 ticket 應歸屬的版本。

**錯誤思路**：
```
Phase 4 完成（v0.1.0 功能實作）
    → 發現技術債：需要遷移共用函式、修正 CLI 架構
    → 執行 /ticket create
    → 系統詢問 version → 使用「當前活躍版本」→ v0.1.1（新專案版本）
    → 技術債 ticket 建在 v0.1.1
    → v0.1.0 的改善工作遺失追蹤
```

**根本原因**：技術債 ticket 的版本應由「**觸發它的功能實作所在版本**」決定，而非「建立 ticket 時的系統活躍版本」。

### 解決方案

建立技術債 ticket 時，明確指定版本：

```bash
# 正確：明確指定與功能實作相同的版本
ticket create --version 0.1.0 --wave 7 --action "遷移" --target "..."

# 錯誤：省略 --version，使用預設活躍版本
ticket create --wave 7 --action "遷移" --target "..."
```

**版本歸屬判斷規則**：

| ticket 類型 | 版本歸屬 | 說明 |
|------------|---------|------|
| Phase 4 技術債 | 與功能實作版本相同 | 是對本次實作的改善 |
| 多視角審查發現的問題 | 與審查對象版本相同 | 是對本次實作的反饋 |
| 新版本規劃 | 下一版本 | 全新需求，非當前實作的後續 |

### 預防措施

1. **Phase 4 / 審查後建立 ticket 時**，先確認「這個 ticket 是為了改善哪個版本的實作？」再決定 `--version` 參數
2. **`/tech-debt-capture` 使用時**，確認 skill 使用的版本參數與功能實作版本一致
3. **Wave 收尾確認**（AskUserQuestion #3）時，PM 應同時確認技術債 ticket 的版本歸屬是否正確
4. 建立 ticket 後，快速確認 `ticket track summary` 的版本分布是否符合預期

### 行為模式分析

此錯誤屬於「上下文切換遺漏」模式：

| 步驟 | 錯誤行為 | 正確行為 |
|------|---------|---------|
| Phase 4 完成 | 直接執行 /ticket create | 先問「這個 ticket 屬於哪個版本？」 |
| 版本選擇 | 使用系統預設活躍版本 | 明確指定功能實作版本 |
| 確認 | 未驗證 ticket 的版本歸屬 | 執行後確認 ticket 在正確版本下 |

> **核心教訓**：技術債 ticket 的版本歸屬是「功能視角」而非「時間視角」——它屬於產生它的那個實作，不屬於建立它時的那個時間點。
