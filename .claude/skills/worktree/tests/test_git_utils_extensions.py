"""
Test git_utils 擴充函式

測試 is_in_worktree 和路徑豁免判定函式
"""

import pytest
import sys
from pathlib import Path
from unittest.mock import patch

# 動態新增 scripts 目錄到 Python 路徑
scripts_dir = Path(__file__).resolve().parent.parent / "scripts"
sys.path.insert(0, str(scripts_dir))


class TestIsInWorktree:
    """is_in_worktree 函式測試（由 W9-002.3 實作）

    此測試為骨架，實際實作由 basil-hook-architect 在 git_utils.py 中完成
    """

    def test_is_in_worktree_placeholder(self):
        """placeholder test"""
        # 實作於 W9-002.3
        pass


class TestIsExemptPathOnProtectedBranch:
    """路徑豁免判定函式測試（由 W9-002.3 實作）

    此測試為骨架，實際實作由 basil-hook-architect 在 branch-verify-hook 中完成
    """

    def test_exempt_path_placeholder(self):
        """placeholder test"""
        # 實作於 W9-002.3
        pass
