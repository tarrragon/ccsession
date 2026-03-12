# Phase 2：測試設計指引

## Phase 目標

根據 Phase 1 的功能規格和行為場景，設計完整的測試案例，確保測試覆蓋所有業務行為。

**核心問題**：「什麼樣的測試能充分驗證這個功能的正確性？」

---

## 產出（Layer 1）

Phase 2 完成後，必須產出：

- [ ] 測試案例清單（涵蓋正常/異常/邊界）
- [ ] GWT（Given-When-Then）格式的測試規格
- [ ] 測試檔案結構規劃（位置、命名）
- [ ] 測試策略說明（測試金字塔層次）

---

## 測試策略設計

### 測試金字塔

```
              端對端測試（少量）
           /       UI 整合       \
         /   整合測試（中量）    \
       /    模組間互動 / API      \
     /  單元測試（大量）          \
   /   函式、類別、邏輯            \
```

| 層次 | 測試對象 | 數量 | 速度 |
|------|---------|------|------|
| 單元測試 | 函式、類別、業務邏輯 | 最多 | 最快 |
| 整合測試 | 模組間互動、資料層 | 中量 | 較慢 |
| 端對端測試 | 完整使用者流程 | 最少 | 最慢 |

**原則**：測試金字塔底部穩定，不要讓整合測試做單元測試的工作。

### 測試類型選擇

| 功能類型 | 建議測試層次 |
|---------|------------|
| 業務邏輯（Domain） | 單元測試（純函式，無外部依賴） |
| 應用服務（Use Case） | 單元測試（Mock 外部依賴） |
| 資料存取（Repository） | 整合測試（真實資料庫或 Mock） |
| UI 元件 | 元件測試 + 少量整合 |
| 完整功能流程 | 端對端測試（少量核心路徑） |

---

## BDD / Given-When-Then 設計

### GWT 格式

```
場景 {編號}：{業務行為描述}

Given: {系統的前置狀態}
  AND: {額外前置條件}（可選）
When: {觸發的操作}
  AND: {額外操作}（可選）
Then: {預期的可觀察結果}
  AND: {額外預期結果}（可選）
```

### 場景設計原則

| 原則 | 說明 |
|------|------|
| 每個場景獨立 | 不依賴其他場景的執行順序 |
| 業務語言 | 用業務語言描述，不用技術術語 |
| 可觀察結果 | Then 必須描述可驗證的外部行為 |
| 最小化 Given | 只設定測試所需的最少前置條件 |

### 場景類型覆蓋要求

| 類型 | 說明 | 必要性 |
|------|------|--------|
| 正常流程 | 標準成功路徑（Happy Path） | 必要 |
| 異常流程 | 輸入錯誤、業務規則拒絕 | 必要 |
| 邊界條件 | 最小值、最大值、邊界附近 | 必要 |
| 並發/競爭 | 同時操作、狀態競爭（如適用） | 視情況 |
| 效能邊界 | 大量資料、超時（如有效能需求） | 視情況 |

### 行為鏈式設計

對於涉及多步驟的功能，測試應基於行為事件逐步推演：

```
A（初始狀態）→ B（操作後狀態）→ C（進一步操作後狀態）

測試 1：驗證 A → B 的轉換
測試 2：Given B 的前置狀態，驗證 B → C 的轉換
```

這樣每個測試都是獨立可執行的，同時能表達完整的業務流程。

---

## 測試案例設計

### 測試案例格式

```markdown
### 測試案例：{案例名稱}

**類型**：單元 / 整合 / 端對端
**對應場景**：場景 {編號}
**測試對象**：{被測試的函式/類別/流程}

**Given**：
- {前置條件設定}

**When**：
- {操作}

**Then**：
- {預期結果}
- {預期的副作用（如有）}

**測試資料**：
- 輸入：{具體測試資料}
- 預期輸出：{具體預期值}
```

### 邊界條件識別

對每個輸入欄位，考慮：

| 邊界類型 | 範例（字串欄位，長度 1-100） |
|---------|---------------------------|
| 最小有效值 | 長度 = 1 |
| 最大有效值 | 長度 = 100 |
| 低於最小值 | 長度 = 0（空字串）|
| 超過最大值 | 長度 = 101 |
| 特殊字元 | 包含 SQL 注入字元、Unicode |
| Null / 未提供 | 欄位為 null 或缺少 |

---

## 測試檔案結構規劃

### 命名規範

| 規則 | 說明 |
|------|------|
| 測試檔案名稱 | `{被測試模組名稱}_test.{副檔名}` |
| 測試函式名稱 | 描述被測試的行為，而非實作細節 |
| 避免 | `test1`, `testMethod`, `testHappy` 等無意義名稱 |

### 目錄結構

測試檔案位置應與被測試的原始碼對應：

```
src/
  features/
    search/
      domain/
        search_query.dart

test/
  features/
    search/
      domain/
        search_query_test.dart
```

---

## 測試規格書（Phase 2 產出文件）

```markdown
## Phase 2 測試規格書

### 功能：{功能名稱}
### 測試策略：{說明採用的測試層次和理由}

---

### 場景清單

| 場景 | 類型 | 描述 | 優先級 |
|------|------|------|--------|
| 場景 1 | 正常流程 | {描述} | 高 |
| 場景 2 | 異常流程 | {描述} | 高 |
| 場景 3 | 邊界條件 | {描述} | 中 |

---

### 場景 1：{名稱}

Given: {前置條件}
When: {操作}
Then: {預期結果}

測試資料：
- 輸入：{值}
- 預期輸出：{值}

---

### 測試檔案規劃

| 測試檔案 | 測試類型 | 場景覆蓋 |
|---------|---------|---------|
| {路徑} | 單元測試 | 場景 1、2、3 |
```

---

## 測試實戰教訓

> 源自外部專案的線上除錯經驗。33 個測試全部通過，但實際執行卻有 2 個 Bug。以下五項教訓幫助你從設計階段就避免這些遺漏。

### 教訓 1：測試應驅動真實路徑，不要手動構造預期結果

**問題程式碼（❌ 錯誤）**：

```dart
test('品項分派邏輯', () {
  // 手動構造預期結果，沒有走過真正的分派邏輯
  final result = OnlineOrderPrintResult(
    itemPrinterMapping: {
      'item-1': 'kitchen-2',
      'item-2': 'kitchen-1',
    },
  );
  record.applyPrintResult(result);
  expect(record.kitchenItemPrintJobs['item-1']!.printerId, 'kitchen-2');
});
```

這個測試名稱叫「品項分派邏輯」，但實際上測的只是 `applyPrintResult` 能不能儲存資料，分派邏輯（`_buildItemPrinterMapping`）根本沒被執行過。

**修正後（✅ 正確）**：

```dart
test('2 台空 productNames 印表機：品名奇偶分配到不同印表機', () async {
  PrintCenter.to.initFakeKitchenPrinters();
  final result = await handler.printAppendedOrder(payload, printMain: false);
  expect(result.itemPrinterMapping['item-1'], 'kitchen-2');
  expect(result.kitchenResults['kitchen-1'], isTrue);
});
```

透過 `printAppendedOrder` 驅動，讓真正的分派邏輯跑一遍。

**教訓**：測試應該驅動被測程式碼的真實路徑，而非用手動構造的資料驗證資料搬運是否正確。

---

### 教訓 2：只測「覆寫的方法」會遺漏「繼承的方法」

**問題程式碼（❌ 錯誤）**：

```dart
test('sendBytes 不報錯', () async {
  final printer = FakePrinterAdapter('test-printer');
  await printer.init();
  await printer.sendBytes([1, 2, 3]); // sendBytes 是 FakePrinter 覆寫的 no-op
});
```

但實際列印路徑呼叫的是 `printText()`——這是從 `GeneralPrinterAdapter` 繼承的方法，內部依賴 `generator`。`sendBytes` 不用 `generator`，所以永遠不會觸發 Bug。

**修正後（✅ 正確）**：

```dart
// ✅ 測試實際列印路徑會用到的方法
test('init 後 printText 不報錯（驗證 generator 已初始化）', () async {
  final printer = FakePrinterAdapter('test-printer');
  await printer.init();
  await printer.printText('測試文字'); // 走 generator.text() → sendBytes
});

// ✅ 反向驗證：確認未初始化的行為
test('未 init 就呼叫 printText 會拋出錯誤', () async {
  final printer = FakePrinterAdapter('test-printer');
  expect(() => printer.printText('測試文字'), throwsA(isA<Error>()));
});
```

**教訓**：覆寫子類別時，要測試「上層呼叫者實際會用到的方法」，而非只測「你覆寫了什麼」。

---

### 教訓 3：驗證「有沒有」不等於驗證「對不對」

**問題程式碼（❌ 錯誤）**：

```dart
// 只檢查 key 存在，不檢查 value
expect(result.kitchenResults.containsKey('kitchen-1'), isTrue);
expect(result.kitchenResults.containsKey('kitchen-2'), isTrue);
```

因為缺少 `ReceiptBuilderService`，列印路徑在 `buildReceiptLines` 就斷了，try-catch 回傳 `false`。但測試只檢查 `containsKey`，不管是 `true` 還是 `false`，都會通過。

**修正後（✅ 正確）**：

```dart
// ✅ 驗證列印結果的值
expect(result.kitchenResults['kitchen-1'], isTrue,
    reason: '廚房1 列印應成功');
expect(result.kitchenResults['kitchen-2'], isTrue,
    reason: '廚房2 列印應成功');
```

要讓值為 `true`，就必須讓完整路徑跑通——這迫使我們補上 `FakeReceiptBuilderService`：

```dart
class FakeReceiptBuilderService extends ReceiptBuilderService {
  @override
  Future<List<ReceiptLine>> buildReceiptLines(
    ReceiptData data, ReceiptTemplate template,
  ) async {
    return [ReceiptLine.singleLine(data.title)];
  }
}
```

**教訓**：斷言要驗證「結果的值」，不要只驗證「結果的存在」。特別是 Map、List 這類容器，`containsKey` / `isNotEmpty` 不等於正確。

---

### 教訓 4：整合測試與單元測試的分工

不同層次的測試抓到的 Bug 是不同的：

```
                    單元測試                     整合測試
─────────────────────────────────────────────────────────
測什麼？          單一方法的輸入輸出             多個元件串接的結果
能抓到什麼 Bug？  演算法邏輯錯誤                 初始化遺漏、依賴缺失、
                                                介面不匹配、狀態傳遞錯誤
本案例中          KitchenPrinterConfig           printAppendedOrder +
                  .handlesProduct                PrintCenter + FakePrinter +
                  → 匹配邏輯正確                 ReceiptBuilderService
                                                → 端到端路徑正確
```

**原則**：如果功能涉及「多個元件協作」，只寫單元測試是不夠的。

---

### 教訓 5：替 try-catch 設計專門的測試

Try-catch 是測試的天敵——它會把錯誤吞掉，讓測試誤以為一切正常。

**問題程式碼**：

```dart
// 生產程式碼中的 try-catch
Future<bool> _printKitchenReceipt(...) async {
  try {
    final lines = await _receiptBuilder.buildReceiptLines(data, template);
    await _printCenter.printReceiptLines(lines: lines, printer: config.printer);
    return true;
  } catch (e) {
    debugPrint('kitchen print failed: $e');
    return false;  // ← Bug 被吞掉，變成靜默失敗
  }
}
```

**對策**：

1. **斷言成功路徑的值**：不要只檢查「沒拋錯」，要檢查回傳值是 `true`
2. **提供完整的依賴**：讓 try 區塊能完整執行，而非依賴 catch 來「通過」測試
3. **寫專門的失敗測試**：故意製造失敗條件，驗證錯誤處理行為

```dart
// 正確的 try-catch 測試策略
test('完整列印路徑成功', () async {
  // 提供完整依賴
  PrintCenter.to.initFakePrinters();
  final receiptBuilder = FakeReceiptBuilderService();

  // 驗證成功情況
  final result = await handler._printKitchenReceipt(data, receiptBuilder);
  expect(result, isTrue);
});

test('缺少依賴時返回 false（try-catch 生效）', () async {
  // 故意不提供 receiptBuilder
  final result = await handler._printKitchenReceipt(data, null);
  expect(result, isFalse);
});
```

---

## Fake/Mock 設計原則

| 維度 | Fake（假實作） | Mock（模擬物件） |
|------|---|---|
| 適用場景 | 需要跑通完整路徑 | 只需驗證互動次數/參數 |
| 本案例 | FakeReceiptBuilderService、FakePrinterAdapter | 不適用 |

**設計 Fake 時的檢查清單**：

- [ ] 繼承/實作的方法中，有哪些是「上層呼叫者實際會用到的」？
- [ ] 這些方法依賴哪些「內部狀態」（如 `late` 變數）？
- [ ] Fake 的 `init()` 是否正確初始化了這些內部狀態？
- [ ] Fake 回傳的資料是否足以讓下游繼續執行？

---

## 檢查清單：避免「測試全過但有 Bug」

寫完測試案例後，用以下問題自我檢查：

1. **路徑覆蓋**：這個測試有沒有走過被測功能的「關鍵程式碼路徑」？還是只測了資料搬運？
2. **斷言強度**：斷言是檢查「值是否正確」還是只檢查「東西存不存在」？
3. **依賴完整性**：被測程式碼的所有依賴（Service、Adapter）是否都有提供？缺少的依賴是否被 try-catch 靜默吞掉？
4. **繼承鏈**：如果用了 Fake/Mock 子類別，上層呼叫者用到的「繼承方法」是否有被測試到？
5. **反向驗證**：是否有測試「錯誤情境」來確認你理解了 Bug 的根因？

---

## 轉換條件

### 進入 Phase 2 的條件

- Phase 1 功能規格完整
- API 介面定義完成
- 驗收標準明確
- 行為場景（GWT）已提取

### 退出 Phase 2 的條件（進入 Phase 3a）

- [ ] 測試案例涵蓋正常/異常/邊界情境
- [ ] 所有場景以 GWT 格式規格化
- [ ] 測試檔案結構規劃完成
- [ ] 測試策略說明完整

> **框架整合**：Phase 2 由測試設計者角色執行，完成後自行提交（git commit），更新任務狀態，回報：「Phase 2 完成，測試規格書已提交」。

---

**Last Updated**: 2026-03-12
**Version**: 1.1.0 - 整合外部專案測試教訓：五項經驗、Fake/Mock 原則、避免 Bug 檢查清單（0.1.0-W46-001）
