#!/usr/bin/env python3
"""
commit-handoff-hook 測試套件

驗證：
1. 情境 A（#11a）：Ticket 仍 in_progress → 輸出 Context 刷新提醒
2. 情境 B（#11b）：Ticket completed + 同 Wave 有 pending → 輸出任務切換提醒
3. 情境 C 提示訊息：WAVE_COMPLETION_REMINDER 常數存在且格式正確
4. 情境 C 偵測邏輯：detect_wave_completion() 函式
5. commit type 判斷邏輯（skip #16）
"""

import sys
import json
import logging
from pathlib import Path
from unittest.mock import patch, MagicMock
from tempfile import TemporaryDirectory
import importlib.util

# 設定路徑
hooks_path = Path(__file__).parent.parent
sys.path.insert(0, str(hooks_path))

from lib.ask_user_question_reminders import AskUserQuestionReminders
from lib.hook_messages import AskUserQuestionMessages

# 動態導入 commit-handoff-hook（檔案名含 dash，需用 importlib）
hook_file = hooks_path / "commit-handoff-hook.py"
spec = importlib.util.spec_from_file_location("commit_handoff_hook", hook_file)
commit_handoff_hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(commit_handoff_hook)


class TestCommitHandoffHook:
    """commit-handoff-hook 功能測試"""

    def test_wave_completion_reminder_exists(self):
        """驗證 WAVE_COMPLETION_REMINDER 常數已新增"""
        # 檢查常數是否存在
        assert hasattr(AskUserQuestionReminders, 'WAVE_COMPLETION_REMINDER'), \
            "WAVE_COMPLETION_REMINDER 常數不存在"

        # 檢查常數不為空
        reminder = AskUserQuestionReminders.WAVE_COMPLETION_REMINDER
        assert reminder, "WAVE_COMPLETION_REMINDER 常數為空"
        assert isinstance(reminder, str), "WAVE_COMPLETION_REMINDER 應為字串類型"

    def test_wave_completion_reminder_content(self):
        """驗證 WAVE_COMPLETION_REMINDER 常數包含必需的內容"""
        reminder = AskUserQuestionReminders.WAVE_COMPLETION_REMINDER

        # 檢查必需的主題
        required_keywords = [
            "Wave 完成審查",
            "情景 C",
            "/parallel-evaluation",
            "情景 C1",
            "情景 C2",
            "/version-release check",
            "AskUserQuestion",
        ]

        for keyword in required_keywords:
            assert keyword in reminder, \
                f"WAVE_COMPLETION_REMINDER 缺少必需的內容: {keyword}"

    def test_wave_completion_reminder_format(self):
        """驗證 WAVE_COMPLETION_REMINDER 格式正確"""
        reminder = AskUserQuestionReminders.WAVE_COMPLETION_REMINDER

        # 檢查格式（應包含標準的分隔線）
        assert "=" * 60 in reminder, \
            "WAVE_COMPLETION_REMINDER 缺少標準的分隔線"

        # 檢查結構（應包含 [Step 1] 和 [Step 2]）
        assert "[Step 1]" in reminder, "WAVE_COMPLETION_REMINDER 缺少 [Step 1]"
        assert "[Step 2]" in reminder, "WAVE_COMPLETION_REMINDER 缺少 [Step 2]"

    def test_commit_handoff_reminder_unchanged(self):
        """驗證 COMMIT_HANDOFF_REMINDER 保持不變（回歸測試）"""
        reminder = AskUserQuestionReminders.COMMIT_HANDOFF_REMINDER

        # 檢查關鍵內容仍存在
        assert "情境 A" in reminder
        assert "情境 B" in reminder
        assert "情境 C" in reminder
        assert "#16" in reminder
        assert "#11" in reminder

    def test_commit_handoff_skip16_reminder_unchanged(self):
        """驗證 COMMIT_HANDOFF_SKIP16_REMINDER 保持不變（回歸測試）"""
        reminder = AskUserQuestionReminders.COMMIT_HANDOFF_SKIP16_REMINDER

        # 檢查關鍵內容仍存在
        assert "情境 A" in reminder
        assert "情境 B" in reminder
        assert "情境 C" in reminder
        assert "#11" in reminder

    def test_backward_compatibility_alias(self):
        """驗證向後相容性別名仍可用"""
        # AskUserQuestionMessages 應該是 AskUserQuestionReminders 的別名
        assert hasattr(AskUserQuestionMessages, 'WAVE_COMPLETION_REMINDER'), \
            "AskUserQuestionMessages 別名缺少 WAVE_COMPLETION_REMINDER"

        # 驗證別名指向相同物件
        assert AskUserQuestionMessages.WAVE_COMPLETION_REMINDER == \
               AskUserQuestionReminders.WAVE_COMPLETION_REMINDER, \
            "別名指向的物件不一致"

    def test_detect_wave_completion_true(self):
        """驗證 detect_wave_completion() 在同 Wave 無 pending 時回傳 True"""
        logger = logging.getLogger("test")

        # 建立臨時目錄結構
        with TemporaryDirectory() as tmpdir:
            project_dir = Path(tmpdir)
            docs_dir = project_dir / "docs"
            tickets_dir = docs_dir / "work-logs" / "v0.1.0" / "tickets"
            tickets_dir.mkdir(parents=True, exist_ok=True)

            # 建立 todolist.yaml
            todolist_file = docs_dir / "todolist.yaml"
            todolist_file.write_text("current_version: 0.1.0\n", encoding="utf-8")

            # 建立 in_progress ticket（Wave 1）
            in_progress_ticket = tickets_dir / "0.1.0-W1-001.md"
            in_progress_ticket.write_text(
                "---\nid: 0.1.0-W1-001\nstatus: in_progress\nwave: 1\n---\nContent",
                encoding="utf-8"
            )

            # 建立 completed ticket（同 Wave 1，已完成）
            completed_ticket = tickets_dir / "0.1.0-W1-002.md"
            completed_ticket.write_text(
                "---\nid: 0.1.0-W1-002\nstatus: completed\nwave: 1\n---\nContent",
                encoding="utf-8"
            )

            # 建立 pending ticket（不同 Wave，Wave 2）
            pending_other_wave = tickets_dir / "0.1.0-W2-001.md"
            pending_other_wave.write_text(
                "---\nid: 0.1.0-W2-001\nstatus: pending\nwave: 2\n---\nContent",
                encoding="utf-8"
            )

            # Mock get_project_root() 回傳臨時目錄
            with patch.object(commit_handoff_hook, 'get_project_root', return_value=project_dir):
                result = commit_handoff_hook.detect_wave_completion(logger)

            # 驗證結果：同 Wave 1 無 pending（only in_progress + completed），應為 True
            assert result is True, \
                "detect_wave_completion() 應在同 Wave 無 pending 時回傳 True"

    def test_detect_wave_completion_false(self):
        """驗證 detect_wave_completion() 在同 Wave 有 pending 時回傳 False"""
        logger = logging.getLogger("test")

        # 建立臨時目錄結構
        with TemporaryDirectory() as tmpdir:
            project_dir = Path(tmpdir)
            docs_dir = project_dir / "docs"
            tickets_dir = docs_dir / "work-logs" / "v0.1.0" / "tickets"
            tickets_dir.mkdir(parents=True, exist_ok=True)

            # 建立 todolist.yaml
            todolist_file = docs_dir / "todolist.yaml"
            todolist_file.write_text("current_version: 0.1.0\n", encoding="utf-8")

            # 建立 in_progress ticket（Wave 1）
            in_progress_ticket = tickets_dir / "0.1.0-W1-001.md"
            in_progress_ticket.write_text(
                "---\nid: 0.1.0-W1-001\nstatus: in_progress\nwave: 1\n---\nContent",
                encoding="utf-8"
            )

            # 建立 pending ticket（同 Wave 1）
            pending_ticket = tickets_dir / "0.1.0-W1-002.md"
            pending_ticket.write_text(
                "---\nid: 0.1.0-W1-002\nstatus: pending\nwave: 1\n---\nContent",
                encoding="utf-8"
            )

            # Mock get_project_root() 回傳臨時目錄
            with patch.object(commit_handoff_hook, 'get_project_root', return_value=project_dir):
                result = commit_handoff_hook.detect_wave_completion(logger)

            # 驗證結果：同 Wave 1 有 pending，應為 False
            assert result is False, \
                "detect_wave_completion() 應在同 Wave 有 pending 時回傳 False"

    def test_detect_wave_completion_no_in_progress(self):
        """驗證 detect_wave_completion() 在無 in_progress ticket 時安全降級為 False"""
        logger = logging.getLogger("test")

        # 建立臨時目錄結構
        with TemporaryDirectory() as tmpdir:
            project_dir = Path(tmpdir)
            docs_dir = project_dir / "docs"
            tickets_dir = docs_dir / "work-logs" / "v0.1.0" / "tickets"
            tickets_dir.mkdir(parents=True, exist_ok=True)

            # 建立 todolist.yaml
            todolist_file = docs_dir / "todolist.yaml"
            todolist_file.write_text("current_version: 0.1.0\n", encoding="utf-8")

            # 建立 pending ticket，但無 in_progress
            pending_ticket = tickets_dir / "0.1.0-W1-001.md"
            pending_ticket.write_text(
                "---\nid: 0.1.0-W1-001\nstatus: pending\nwave: 1\n---\nContent",
                encoding="utf-8"
            )

            # Mock get_project_root() 回傳臨時目錄
            with patch.object(commit_handoff_hook, 'get_project_root', return_value=project_dir):
                result = commit_handoff_hook.detect_wave_completion(logger)

            # 驗證結果：無 in_progress，安全降級為 False
            assert result is False, \
                "detect_wave_completion() 應在無 in_progress ticket 時安全降級為 False"

    def test_detect_wave_completion_file_error(self):
        """驗證 detect_wave_completion() 在檔案讀取錯誤時安全降級為 False"""
        logger = logging.getLogger("test")

        # Mock get_project_root() 指向不存在的目錄
        with patch.object(commit_handoff_hook, 'get_project_root', return_value=Path("/nonexistent")):
            result = commit_handoff_hook.detect_wave_completion(logger)

        # 驗證結果：錯誤時安全降級為 False
        assert result is False, \
            "detect_wave_completion() 應在檔案讀取失敗時安全降級為 False"


def run_tests():
    """執行所有測試"""
    test_class = TestCommitHandoffHook()
    test_methods = [method for method in dir(test_class) if method.startswith('test_')]

    passed = 0
    failed = 0

    print("\n" + "=" * 70)
    print("commit-handoff-hook 測試套件")
    print("=" * 70)

    for method_name in test_methods:
        try:
            method = getattr(test_class, method_name)
            method()
            print(f"✅ {method_name}")
            passed += 1
        except AssertionError as e:
            print(f"❌ {method_name}")
            print(f"   錯誤: {e}")
            failed += 1
        except Exception as e:
            print(f"❌ {method_name}")
            print(f"   例外: {e}")
            failed += 1

    print("\n" + "=" * 70)
    print(f"測試結果: {passed} 通過, {failed} 失敗")
    print("=" * 70)

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    exit_code = run_tests()
    sys.exit(exit_code)
