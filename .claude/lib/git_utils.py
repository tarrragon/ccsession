#!/usr/bin/env python3
"""
Git 操作共用工具

提供統一的 Git 命令執行和分支管理功能。
消除 branch-verify-hook.py, branch-status-reminder.py 等檔案中的重複程式碼。

主要功能:
- run_git_command: 執行 git 命令
- get_current_branch: 獲取當前分支
- get_project_root: 獲取專案根目錄
- get_uncommitted_files: 獲取未提交變更檔案列表
- get_worktree_list: 獲取 worktree 列表
- is_protected_branch: 檢查是否為保護分支
- is_allowed_branch: 檢查是否為允許編輯的分支
"""

import fnmatch
import os
import sys
import subprocess
from typing import Optional


# ===== 分支配置常數 =====

# Worktree 輸出前綴長度（避免魔法數字）
WORKTREE_PREFIX_LEN = len("worktree ")  # 9
BRANCH_PREFIX_LEN = len("branch ")      # 7
REFS_HEADS_PREFIX = "refs/heads/"

# 保護分支列表（支援 glob 模式）
PROTECTED_BRANCHES = [
    "main",
    "master",
    "develop",
    "release/*",
    "production",
]

# 允許編輯的分支模式
ALLOWED_BRANCHES = [
    "feat/*",
    "feature/*",
    "fix/*",
    "hotfix/*",
    "bugfix/*",
    "chore/*",
    "docs/*",
    "refactor/*",
    "test/*",
]


def run_git_command(
    args: list[str],
    cwd: Optional[str] = None,
    timeout: int = 10
) -> tuple[bool, str]:
    """
    執行 git 命令並返回結果

    Args:
        args: git 命令參數列表（不含 'git'）
        cwd: 執行目錄，預設為當前目錄
        timeout: 命令超時時間（秒）

    Returns:
        tuple[bool, str]: (是否成功, 輸出內容或錯誤訊息)

    Example:
        success, output = run_git_command(["branch", "--show-current"])
        success, output = run_git_command(["status"], cwd="/path/to/repo")
    """
    try:
        result = subprocess.run(
            ["git"] + args,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        if result.returncode == 0:
            return True, result.stdout.strip()
        else:
            return False, result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, f"Command timed out after {timeout}s"
    except FileNotFoundError:
        return False, "git command not found"
    except Exception as e:
        error_msg = str(e)
        print(f"[Error] git command failed: {error_msg}", file=sys.stderr)
        return False, error_msg


def get_current_branch() -> Optional[str]:
    """
    獲取當前分支名稱

    Returns:
        str | None: 分支名稱，如果無法獲取則返回 None

    Example:
        branch = get_current_branch()
        if branch:
            print(f"Current branch: {branch}")
    """
    success, output = run_git_command(["branch", "--show-current"])
    return output if success and output else None


def get_project_root() -> str:
    """
    獲取專案根目錄（git 倉庫根目錄）

    Returns:
        str: 專案根目錄路徑，如果無法獲取則返回當前工作目錄

    Example:
        root = get_project_root()
        config_path = os.path.join(root, ".claude", "config.json")
    """
    success, output = run_git_command(["rev-parse", "--show-toplevel"])
    return output if success else os.getcwd()


def get_uncommitted_files() -> list[str]:
    """
    獲取未提交變更的檔案列表

    執行 git status --porcelain，返回所有未提交變更的狀態行。
    每行格式為 git porcelain 格式（如 " M file.txt"、"?? new.txt"）。
    空輸出或 git 命令失敗時返回空列表。

    Returns:
        list[str]: 未提交變更的狀態行列表，如果沒有變更或命令失敗則返回空列表

    Example:
        files = get_uncommitted_files()
        if files:
            print(f"有 {len(files)} 個未提交變更")
        for line in files:
            print(f"  {line}")
    """
    success, output = run_git_command(["status", "--porcelain"])

    if not success or not output:
        return []

    lines = output.split("\n")
    return [line for line in lines if line.strip()]


def get_worktree_list() -> list[dict]:
    """
    獲取所有 worktree 列表

    Returns:
        list[dict]: worktree 資訊列表，每個元素包含:
            - path: worktree 路徑
            - branch: 分支名稱（可選）
            - detached: 是否為 detached HEAD（可選）

    Example:
        worktrees = get_worktree_list()
        for wt in worktrees:
            print(f"{wt.get('branch', 'detached')}: {wt['path']}")
    """
    success, output = run_git_command(["worktree", "list", "--porcelain"])
    if not success:
        return []

    worktrees = []
    current_worktree: dict = {}

    for line in output.split("\n"):
        if line.startswith("worktree "):
            if current_worktree:
                worktrees.append(current_worktree)
            # 使用常數避免魔法數字
            current_worktree = {"path": line[WORKTREE_PREFIX_LEN:]}
        elif line.startswith("branch "):
            branch_ref = line[BRANCH_PREFIX_LEN:]
            # 移除 refs/heads/ 前綴
            if branch_ref.startswith(REFS_HEADS_PREFIX):
                branch_ref = branch_ref[len(REFS_HEADS_PREFIX):]
            current_worktree["branch"] = branch_ref
        elif line == "detached":
            current_worktree["detached"] = True

    if current_worktree:
        worktrees.append(current_worktree)

    return worktrees


def is_protected_branch(branch: str) -> bool:
    """
    檢查是否為保護分支

    Args:
        branch: 分支名稱

    Returns:
        bool: 如果是保護分支返回 True

    Example:
        if is_protected_branch("main"):
            print("Warning: protected branch!")
    """
    for pattern in PROTECTED_BRANCHES:
        if fnmatch.fnmatch(branch, pattern):
            return True
    return False


def is_allowed_branch(branch: str) -> bool:
    """
    檢查是否為允許編輯的分支

    Args:
        branch: 分支名稱

    Returns:
        bool: 如果是允許編輯的分支返回 True

    Example:
        if is_allowed_branch("feat/new-feature"):
            print("Safe to edit")
    """
    for pattern in ALLOWED_BRANCHES:
        if fnmatch.fnmatch(branch, pattern):
            return True
    return False


def is_in_worktree() -> bool:
    """
    檢查當前工作目錄是否在 git worktree（非主倉庫）中

    在 worktree 中，git rev-parse --git-dir 返回的路徑會是
    /path/to/.git/worktrees/name，而 --git-common-dir 返回 /path/to/.git
    兩者不同即表示在 worktree 中。

    在主倉庫中，兩者都返回 /path/to/.git（相同）

    Returns:
        bool: True 表示在 worktree 中，False 表示在主倉庫或非 git 環境

    Example:
        if is_in_worktree():
            print("Currently in a feature worktree")
        else:
            print("Currently in the main repository")
    """
    try:
        # 取得主 .git 目錄路徑
        success_common, git_common_dir = run_git_command(["rev-parse", "--git-common-dir"])
        if not success_common:
            return False

        # 取得當前 .git 目錄路徑
        success_dir, git_dir = run_git_command(["rev-parse", "--git-dir"])
        if not success_dir:
            return False

        # 正規化路徑以便正確比較（移除相對路徑等）
        git_common_dir = os.path.abspath(git_common_dir)
        git_dir = os.path.abspath(git_dir)

        # 比較兩者
        # 在 worktree 中：不同（git_dir 包含 /worktrees/ 路徑）
        # 在主倉庫中：相同
        return git_common_dir != git_dir

    except Exception as e:
        # 錯誤時保守預設為主倉庫
        print(f"[Warning] is_in_worktree check failed: {e}", file=sys.stderr)
        return False



def generate_worktree_info() -> str:
    """
    生成 worktree 資訊字串（用於顯示）

    Returns:
        str: 格式化的 worktree 資訊，如果只有一個 worktree 則返回空字串
    """
    worktrees = get_worktree_list()
    if len(worktrees) <= 1:
        return ""

    info = "\n現有 Worktree:\n"
    for wt in worktrees:
        branch = wt.get("branch", "detached")
        path = wt.get("path", "unknown")
        info += f"  - {branch}: {path}\n"
    return info
