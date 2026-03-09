#!/usr/bin/env python3
"""
Phase 3b 判斷邏輯測試案例

測試 task-dispatch-readiness-check.py 是否能正確識別 Phase 3b 任務
"""

import sys
import os

# 將 .claude/hooks 加入 sys.path
hooks_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, hooks_dir)

# 動態導入 Hook 腳本
import importlib.util
spec = importlib.util.spec_from_file_location(
    "task_dispatch_readiness_check",
    os.path.join(hooks_dir, "task-dispatch-readiness-check.py")
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

detect_task_type = module.detect_task_type


def test_phase3b_detection():
    """測試 Phase 3b 關鍵字識別"""

    test_cases = [
        # Phase 3b 正面案例
        {
            "prompt": "Phase 3b: ImportService Flutter/Dart 實作",
            "expected": "Phase 3b 實作",
            "description": "標準 Phase 3b 格式"
        },
        {
            "prompt": "[Phase 3b 實作] JsonValidationService",
            "expected": "Phase 3b 實作",
            "description": "標籤式 Phase 3b 格式"
        },
        {
            "prompt": "將 Phase 3a 虛擬碼轉換為 Flutter/Dart 實作",
            "expected": "Phase 3b 實作",
            "description": "虛擬碼轉換描述"
        },
        {
            "prompt": "parsley-flutter-developer 實作 ImportService",
            "expected": "Phase 3b 實作",
            "description": "包含代理人名稱"
        },
        # Phase 3a 負面案例（不應誤判為 Phase 3b）
        {
            "prompt": "Phase 3a: 實作策略規劃 - 提供虛擬碼",
            "expected": "Phase 3a 策略規劃",
            "description": "Phase 3a 虛擬碼設計"
        },
        {
            "prompt": "pepper-test-implementer 提供語言無關策略",
            "expected": "Phase 3a 策略規劃",
            "description": "Phase 3a 代理人"
        },
        # Phase 2 負面案例（不應誤判為 Phase 3b）
        {
            "prompt": "Phase 2: 測試案例設計 - 30 個測試",
            "expected": "Phase 2 測試設計",
            "description": "Phase 2 測試設計"
        },
        # 完成狀態不應判斷為當前 Phase
        {
            "prompt": "基於 Phase 3b 已完成的實作，進行 Phase 4 重構",
            "expected": "Phase 4 重構",
            "description": "Phase 3b 完成，當前是 Phase 4"
        }
    ]

    print("[TEST] Phase 3b 判斷邏輯測試\n")
    print("=" * 80)

    passed = 0
    failed = 0

    for i, test in enumerate(test_cases, 1):
        prompt = test["prompt"]
        expected = test["expected"]
        description = test["description"]

        result = detect_task_type(prompt)

        status = "[PASS] PASS" if result == expected else "[FAIL] FAIL"

        if result == expected:
            passed += 1
        else:
            failed += 1

        print(f"\n測試 {i}: {description}")
        print(f"Prompt: {prompt}")
        print(f"預期: {expected}")
        print(f"實際: {result}")
        print(f"狀態: {status}")
        print("-" * 80)

    print(f"\n\n[METRIC] 測試結果總結")
    print("=" * 80)
    print(f"總測試數: {len(test_cases)}")
    print(f"[PASS] 通過: {passed}")
    print(f"[FAIL] 失敗: {failed}")
    print(f"通過率: {passed / len(test_cases) * 100:.1f}%")

    if failed == 0:
        print("\n[SUCCESS] 所有測試通過！Phase 3b 判斷邏輯修正成功")
        return 0
    else:
        print("\n[WARNING] 部分測試失敗，請檢查判斷邏輯")
        return 1


if __name__ == "__main__":
    sys.exit(test_phase3b_detection())
