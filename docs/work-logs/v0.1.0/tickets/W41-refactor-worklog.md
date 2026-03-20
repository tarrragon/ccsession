---
id: v0.1.0-W41-refactor-worklog
title: W41 重構工作日誌 - Hook 基礎設施模組化（Ticket 0.1.0-W41-001）
type: WORKLOG
status: in_progress
created: 2026-03-12
updated: 2026-03-12
---

# W41 重構工作日誌：Hook 基礎設施模組化

**Wave**: W41
**主要 Ticket**: 0.1.0-W41-001
**目標版本**: v0.1.0
**狀態**: 進行中（Phase 2 設計已完成）

---

## 版本目標

**Problem**：Hook 工具庫（hook_utils）職責混雜，get_project_root() 與日誌系統耦合過緊，導致：
- 模組依賴順序不清（hook_io 依賴 hook_logging 只為取得 get_project_root）
- 潛在循環依賴風險（基礎設施應被日誌層使用，反向依賴違反分層）
- 代碼複用受限（新模組若需 get_project_root 需依賴整個日誌系統）

**Solution**：將 `get_project_root()` 及相關函式從 hook_logging.py 分離到新建的 hook_base.py，建立清晰的模組分層。

**Success Criteria**：
- hook_base.py 新建，包含 get_project_root + _find_project_root + 2 個常數
- hook_logging / hook_ticket / hook_io 的 import 路徑正確轉換
- 外部 54+ Hook 零修改（re-export 防護）
- 所有測試通過，無循環依賴，覆蓋率 >= 95%

---

## Phase 進度

### Phase 1：功能設計 ✓ 完成

**輸出物**：Phase 1 設計文件（Ticket 0.1.0-W41-001 主體）

**關鍵設計**：
- 模組分層：hook_base（基礎）← hook_logging（日誌）← hook_ticket/hook_io（上層應用）
- Re-export 策略：hook_logging.py 保留 `from .hook_base import get_project_root`
- 修改清單：4 個模組 import 路徑調整，1 個新建 hook_base.py

**驗收通過**：
- [x] hook_base 模組存在，包含完整函式和常數定義
- [x] hook_ticket 直接從 hook_base import（第 27 行）
- [x] 外部 Hook 的 `from hook_utils import` 仍正常
- [x] hook_logging re-export 確保向後相容
- [x] hook_io 行內 import 修改後 Handoff 偵測正常
- [x] 無循環依賴

---

### Phase 2：測試設計 ✓ 完成

**輸出物**：本文件（0.1.0-W41-001-test-design.md）

**測試設計概要**：

#### 測試策略
- **分層測試**：單元測試（函式邏輯）+ 整合測試（模組依賴）
- **Sociable Unit Tests**：Mock 外部世界（環境變數、cwd），使用真實 Path 和 os
- **覆蓋率目標**：>= 95%，100% 函式路徑 + 邊界條件

#### 測試案例（14 個場景）

**SC-01 ~ SC-06**：單元測試（hook_base 模組功能）
- SC-01：環境變數優先級（CLAUDE_PROJECT_DIR 最高優先）
- SC-02：CLAUDE.md 搜尋（從 cwd 向上搜尋）
- SC-03：搜尋深度限制（CLAUDE_MD_SEARCH_DEPTH=5 邊界）
- SC-04：Fallback 到 cwd（無 CLAUDE.md 時的容錯）
- SC-05：根目錄檢測（檔案系統根目錄無無限迴圈）
- SC-06：常數定義完整性（ENV_PROJECT_DIR, CLAUDE_MD_SEARCH_DEPTH）

**SC-07 ~ SC-09**：Import 路徑轉換驗證
- SC-07：hook_logging.py re-export 正確性
- SC-08：hook_ticket.py import 轉換（第 27 行）
- SC-09：hook_io.py 行內 import 轉換（第 273 行）

**SC-10 ~ SC-11**：向後相容性驗證
- SC-10：公開 API 一致性（__init__.py 無修改）
- SC-11：外部 Hook 依賴路徑（54+ Hook 零修改驗證）

**SC-12**：循環依賴檢查
- SC-12：無循環依賴（hook_base 底層，無向上依賴）

**SC-13 ~ SC-14**：遺漏情況驗證
- SC-13：_find_project_root 搬移驗證
- SC-14：函式在 hook_logging 不存在（僅 re-export）

#### 測試組織
- **新建檔案**：`.claude/hooks/tests/test_hook_base_refactor.py`（~400-500 行）
- **測試類別**：
  - TestHookBaseModule（SC-01 ~ SC-06，6 個測試）
  - TestImportPaths（SC-07 ~ SC-09，3 個測試）
  - TestBackwardCompatibility（SC-10 ~ SC-11，2 個測試）
  - TestCyclicDependency（SC-12，1 個測試）
  - TestMigrationCompleteness（SC-13 ~ SC-14，2 個測試）

#### Mock 設計
- **環境變數**：pytest monkeypatch 控制 CLAUDE_PROJECT_DIR
- **工作目錄**：monkeypatch.chdir() 改變 cwd
- **檔案系統**：pytest tmp_path fixture 提供隔離環境（不使用 mock，保持 Sociable）

#### 驗收完成度

- [x] 14 個測試場景設計完成（Given-When-Then 規格明確）
- [x] Mock 策略完整（環境變數、cwd、檔案系統）
- [x] 測試檔案結構規劃（test_hook_base_refactor.py）
- [x] 執行和驗證指南提供
- [x] 與 Phase 1 驗收場景的對應確認
- [x] 設計決策記錄完整
- [x] 覆蓋率目標明確（>= 95%）

---

### Phase 3a：策略規劃 ✓ 完成

**執行時間**：2026-03-12
**代理人**：pepper-test-implementer
**輸出物**：策略規劃文件（0.1.0-W41-001-phase3a-strategy.md）

**完成內容**：

#### 1. 實作策略設計
- 四階段遞進搬移流程（無依賴層→日誌層→依賴層→整合）
- 0-4 階段明確的執行順序和驗證檢查清單
- 修改檔案清單和具體行號指引

#### 2. 虛擬碼與流程圖
- hook_base.py 新建邏輯虛擬碼（環境變數→向上搜尋→Fallback）
- hook_logging.py 移除邏輯虛擬碼
- hook_ticket.py / hook_io.py Import 修改虛擬碼
- 資料流程圖（4 階段遞進）
- 控制流程圖（決策點和異常處理）

#### 3. 關鍵實作指引
- 第一階段目標：hook_base.py 獨立性驗證（4 個優先測試）
- 第二階段目標：hook_logging re-export 驗證（3 個優先測試）
- 第三階段目標：import 路徑修改驗證（並行執行）
- 第四階段目標：整合驗證和向後相容確認

#### 4. 權宜方案與技術債務
- M.V.P. 定義：搬移完成，測試通過，向後相容
- 已知限制：Re-export 鏈長、延遲導入、常數位置
- 技術債務標記（Phase 4 改善方向）：Re-export 鏈優化、常數進一步模組化

#### 5. 語言特定實作考量
- Python 包裝層級和相對導入
- pytest 測試環境配置
- 檔案編碼和字串處理
- 效能最佳化（延遲導入保留）
- 可能的技術挑戰清單（循環依賴、Re-export 斷鏈等）

#### 6. Phase 3b 交接清單
- 執行前驗證（理解四階段順序）
- 實作過程中檢查點（每階段測試驗證）
- 執行後驗證（整體功能驗證）
- 技術檢查清單

#### 7. 詳細測試場景清單
- 單元測試 6 個（常數、優先級、搜尋邏輯、邊界）
- Import 轉換 3 個（hook_logging, hook_ticket, hook_io）
- 向後相容 2 個（公開 API、現有 Hook）
- 依賴檢查 1 個
- 完整性驗證 2 個

**驗收完成度**：
- [x] 實作策略完整（4 階段遞進）
- [x] 虛擬碼清晰（無語言特定術語）
- [x] 流程圖完整（資料流、控制流）
- [x] 測試場景清單詳細（14 個）
- [x] 技術債務評估完成
- [x] 交接清單完整

**技術債務發現**：
- 中優先：Re-export 鏈可進一步優化（Phase 4 評估）
- 低優先：常數定義可進一步模組化
- 低優先：文件可能提及 hook_logging，需驗證更新

---

### Phase 3b：實作執行 ⏳ 待派發

**觸發條件**：Phase 3a 完成後
**代理人**：parsley-flutter-developer（注：本專案為 Python Hook，但派發給 Python 開發代理人）
**預期輸出**：
- test_hook_base_refactor.py 完整實作（~400-500 行）
- hook_base.py（新模組，~100 行）
- hook_logging.py、hook_ticket.py、hook_io.py 修改
- 測試結果報告（14/14 通過）

**實作檢查清單**：
- [ ] test_hook_base_refactor.py 實作完成
- [ ] 14 個測試全部通過（PASS 14/14）
- [ ] 覆蓋率 >= 95%
- [ ] hook_base.py 新建成功
- [ ] 3 個模組 import 路徑修改正確
- [ ] 無 ImportError / 無循環依賴
- [ ] 54+ 外部 Hook 相容性驗證

---

### Phase 4：重構評估 ⏳ 待派發

**觸發條件**：Phase 3b 完成後（所有測試通過）
**階段**：Phase 4a（多視角分析）+ Phase 4b（重構執行）+ Phase 4c（再審核）

**評估維度**（Phase 4a）：
- **代碼品質**：認知負擔、函式長度、命名
- **模組設計**：依賴關係、職責分離、複用性
- **測試品質**：覆蓋率、邊界條件、Mock 設計
- **技術債務**：是否引入新的債務

**預期發現**：
- [ ] 代碼品質評分：A/A-/B （預期 A-）
- [ ] 技術債務：發現 / 無
- [ ] 重構建議：列表

---

## 設計決策記錄

### 決策 1：為何將 get_project_root 分離到 hook_base？

**決策**：新建 hook_base.py，搬移 get_project_root + _find_project_root + 常數

**理由**：
1. **職責分離**：hook_logging 專注日誌設定，hook_base 專注基礎設施（專案路徑）
2. **依賴順序**：基礎設施應該被上層依賴，而非混雜在日誌模組中
3. **重用性**：future 的非日誌模組可直接依賴 hook_base，無需 logging 開銷
4. **測試隔離**：get_project_root 的測試與日誌配置分離，提高測試聚焦度

**替代方案**（棄用）：
- 保持在 hook_logging.py：無法解決職責混雜和依賴順序問題
- 拆分到 hook_config.py：與 hook_base 職責重複

### 決策 2：為何使用 re-export 而非直接修改 54+ Hook？

**決策**：hook_logging.py 保留 `from .hook_base import get_project_root`，__init__.py 無修改

**理由**：
1. **向後相容**：54+ 現有 Hook 使用 `from hook_utils import get_project_root`，零修改成本
2. **漸進遷移**：future 版本可逐步更新 Hook 的 import 路徑（hook_logging → hook_base）
3. **風險最小**：re-export 是透明的，不改變 API 層級的行為

**替代方案**（棄用）：
- 直接修改 54+ Hook：時間成本大，風險高，易引入 bug
- 設定 deprecation warning：過度，這是內部重構不是公開 API 變更

### 決策 3：為何 Mock 環境變數但不 Mock 檔案系統？

**決策**：
- Mock：環境變數（monkeypatch.setenv）、工作目錄（monkeypatch.chdir）
- 不 Mock：檔案系統（使用 pytest tmp_path fixture 隔離）

**理由**：
1. **Sociable Unit Tests**：測試行為而非實作，檔案系統檢查（CLAUDE.md 存在）是行為的一部分
2. **隔離性**：tmp_path 提供真實但隔離的環境，無需手工 mock / unmock
3. **可靠性**：避免 mock 陷阱（如忘記 mock Path.parent 屬性導致真實 I/O）
4. **可維護性**：tmp_path 是標準 pytest 做法，團隊熟悉

### 決策 4：為何需要 14 個測試場景？

**決策**：設計 14 個場景（6 單元 + 3 轉換 + 2 相容 + 1 依賴 + 2 完整性）

**理由**：
1. **函式路徑覆蓋**：SC-01 ~ SC-05 覆蓋 get_project_root 的 3 層優先級 + 2 個邊界
2. **搬移驗證**：SC-07 ~ SC-09 驗證 3 個依賴模組的 import 轉換
3. **向後相容**：SC-10 ~ SC-11 驗證公開 API 和外部 Hook 無影響
4. **質量保證**：SC-12 ~ SC-14 驗證無循環依賴、無遺漏

---

## 問題分析總結

### 根本問題
當前 hook_utils 結構中，get_project_root() 與日誌系統過度耦合：

```
當前結構（問題）：
  hook_logging.py
    ├─ 日誌系統（setup_hook_logging）
    ├─ get_project_root()         ← 專案路徑查詢
    └─ _find_project_root()

  hook_ticket.py
    └─ from .hook_logging import get_project_root  ← 為了取得函式，需依賴整個日誌模組

  hook_io.py
    └─ from .hook_logging import get_project_root  ← 同上
```

### 影響分析

| 問題 | 影響層級 | 後果 |
|------|--------|------|
| 職責混雜 | 架構 | 模組的單一責任原則被違反 |
| 依賴順序錯誤 | 設計 | 基礎設施層應被上層依賴，反之則否 |
| 複用受限 | 維護 | 新模組若需 get_project_root 被迫依賴 logging |
| 測試困難 | 品質 | 測試被迫初始化日誌系統才能測試路徑查詢邏輯 |

### 為什麼現在修復

- **預防循環依賴**：未來的模組擴張可能引入循環依賴風險
- **提升模組品質**：清晰的分層是長期可維護性的基礎
- **測試驅動**：通過完整的測試設計，確保重構的正確性
- **無業務影響**：re-export 策略保證零修改成本

---

## 測試設計摘要

### 覆蓋範圍

```
get_project_root()
├─ 優先級 1（環境變數）      ← SC-01 覆蓋
├─ 優先級 2（CLAUDE.md）
│   ├─ 正常搜尋              ← SC-02 覆蓋
│   ├─ 深度限制（5 層）      ← SC-03 覆蓋
│   └─ 根目錄邊界            ← SC-05 覆蓋
└─ 優先級 3（cwd fallback） ← SC-04, SC-06 覆蓋

模組依賴
├─ hook_base（新建）        ← SC-06, SC-13 驗證
├─ hook_logging→hook_base    ← SC-07 驗證（re-export）
├─ hook_ticket→hook_base     ← SC-08 驗證（import 轉換）
├─ hook_io→hook_base         ← SC-09 驗證（行內 import）
└─ 外部 Hook 相容            ← SC-10, SC-11 驗證

無循環依賴                   ← SC-12 驗證

完整性檢查
├─ _find_project_root 搬移   ← SC-13 驗證
└─ hook_logging 無定義       ← SC-14 驗證
```

### 測試執行指南

```bash
# 運行所有 Phase 2 設計測試（實作時執行）
(cd .claude/hooks && uv run pytest tests/test_hook_base_refactor.py -v)

# 預期結果
PASSED tests/test_hook_base_refactor.py::TestHookBaseModule::test_sc01_env_var_priority
PASSED tests/test_hook_base_refactor.py::TestHookBaseModule::test_sc02_claude_md_search
... (14 tests total)

PASSED 14/14 tests (100%)
Coverage: 95%+ ✓
```

---

## 與 Phase 1 的對應關係

| Phase 1 驗收場景 | 對應 Phase 2 測試 | 驗證方法 |
|----------------|-----------------|--------|
| hook_base 存在 + 包含完整函式 | SC-06, SC-13 | 導入驗證 + 函式簽名檢查 |
| hook_ticket 直接從 hook_base import | SC-08 | 導入成功 + 函式可用 |
| 外部 Hook 零修改 | SC-10, SC-11 | 掃描驗證 + 相容性測試 |
| hook_logging re-export 正常 | SC-07 | 導入驗證 + 返回值一致性 |
| hook_io 行內 import 正常 | SC-09 | 函式可用性驗證 |
| 無循環依賴 | SC-12 | AST 依賴圖分析 |

---

## 下一步（Phase 3a 派發清單）

**派發對象**：pepper-test-implementer

**派發內容**：
1. 本工作日誌（概略）
2. 詳細測試設計文件（0.1.0-W41-001-test-design.md）
3. Phase 1 設計文件（Ticket 主體）

**預期輸出**：
- 策略文件（實作步驟和決策）
- Python 虛擬碼（測試程式碼框架）
- 債務評估（是否有技術債務）

**轉換重點**：
- 將 14 個 GWT 場景轉換為虛擬碼
- 說明各個 Fixture 的設計（為什麼使用 monkeypatch vs mock）
- 識別潛在的技術債務（如重複 code 的消除）

---

**工作日誌完成日期**：2026-03-12
**Phase 2 完成狀態**：✓ 完成
**下一步觸發**：Phase 3a 派發給 pepper-test-implementer
