#!/usr/bin/env python3
"""
Worktree Manager - /worktree SKILL 的核心邏輯

提供 create 和 status 子命令，支援從 Ticket ID 自動推導分支名和 worktree 路徑。

主要功能:
- cmd_create: 建立新 worktree
- cmd_status: 查看 worktree 狀態
- 輔助函式：Ticket ID 驗證、推導、反推等
"""

import os
import re
import sys
from pathlib import Path
from typing import Optional
import subprocess

from constants import (
    FEAT_PREFIX,
    FEAT_PREFIX_LEN,
    PROTECTED_BRANCHES,
    ALLOWED_BRANCH_PATTERNS,
    TICKET_ID_PATTERN,
    WORKTREE_STATUS_OUTPUT_WIDTH,
    DEFAULT_BASE_BRANCH,
)

# 動態新增 .claude/lib 到 Python 路徑
project_root = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(project_root / ".claude" / "lib"))

try:
    from git_utils import (
        run_git_command,
        get_project_root,
        get_current_branch,
        get_worktree_list,
        is_protected_branch,
        is_allowed_branch,
    )
except ImportError as e:
    # #4 修復：ImportError 應寫入 stderr 和日誌，但不中斷程式
    # 改為優雅降級：寫 stderr 提示，但允許程式繼續執行
    import sys
    print(f"[Warning] Failed to import git_utils: {e}", file=sys.stderr)
    print(f"[Warning] Worktree SKILL may not function properly", file=sys.stderr)

    # 定義 fallback 函式，但在呼叫時輸出警告並返回安全預設值
    def run_git_command(args: list[str], cwd: Optional[str] = None, timeout: int = 10) -> tuple[bool, str]:
        """Fallback: 執行 git 命令（降級模式）"""
        return False, "git_utils unavailable"

    def get_project_root() -> str:
        """Fallback: 獲取專案根目錄（降級模式）"""
        return os.getcwd()

    def get_current_branch() -> Optional[str]:
        """Fallback: 獲取當前分支（降級模式）"""
        return None

    def get_worktree_list() -> list[dict]:
        """Fallback: 獲取 worktree 列表（降級模式）"""
        return []

    def is_protected_branch(branch: str) -> bool:
        """Fallback: 檢查保護分支（降級模式）"""
        protected = PROTECTED_BRANCHES + ["release"]  # 包含官方版本的分支清單
        return branch in protected

    def is_allowed_branch(branch: str) -> bool:
        """Fallback: 檢查允許編輯分支（降級模式）"""
        return any(branch.startswith(p) for p in ALLOWED_BRANCH_PATTERNS)


# ===== 核心函式 =====


def is_valid_ticket_id(ticket_id: str) -> bool:
    """
    驗證 Ticket ID 格式是否合法

    Args:
        ticket_id: Ticket ID 字串

    Returns:
        bool: 格式合法返回 True，否則 False

    Example:
        is_valid_ticket_id("0.1.1-W9-002.1")  # True
        is_valid_ticket_id("my-feature")      # False
    """
    return bool(re.match(TICKET_ID_PATTERN, ticket_id))


# #9 修復：為向後相容，保留別名（舊命名）
parse_ticket_id = is_valid_ticket_id


def derive_branch_name(ticket_id: str) -> str:
    """
    從 Ticket ID 推導分支名稱

    Args:
        ticket_id: 合法格式的 Ticket ID

    Returns:
        str: 分支名稱 (feat/{ticket_id})

    Example:
        derive_branch_name("0.1.1-W9-002.1")  # "feat/0.1.1-W9-002.1"
    """
    return f"feat/{ticket_id}"


def derive_worktree_path(ticket_id: str) -> str:
    """
    從 Ticket ID 推導 worktree 絕對路徑

    Args:
        ticket_id: 合法格式的 Ticket ID

    Returns:
        str: worktree 絕對路徑

    Example:
        derive_worktree_path("0.1.1-W9-002.1")
        # "/Users/mac-eric/project/ccsession-0.1.1-W9-002.1"
    """
    project_root = get_project_root()
    project_name = os.path.basename(project_root)
    parent_dir = os.path.dirname(project_root)
    return os.path.join(parent_dir, f"{project_name}-{ticket_id}")


def check_branch_exists(branch: str) -> bool:
    """
    檢查分支是否存在

    Args:
        branch: 分支名稱

    Returns:
        bool: 分支存在返回 True
    """
    success, _ = run_git_command(["rev-parse", "--verify", branch])
    return success


def extract_ticket_id_from_branch(branch: str) -> Optional[str]:
    """
    從分支名稱反推 Ticket ID

    Args:
        branch: 分支名稱（如 "feat/0.1.1-W9-002.1"）

    Returns:
        str | None: Ticket ID，或 None 如果無法辨識

    Example:
        extract_ticket_id_from_branch("feat/0.1.1-W9-002.1")  # "0.1.1-W9-002.1"
        extract_ticket_id_from_branch("main")                  # None
    """
    if not branch.startswith(FEAT_PREFIX):
        return None

    # #10 修復：使用常數 FEAT_PREFIX_LEN 而非魔法數字 5
    potential_ticket_id = branch[FEAT_PREFIX_LEN:]

    if parse_ticket_id(potential_ticket_id):
        return potential_ticket_id

    return None


def get_worktree_ahead_behind(branch: str, base: str = "main") -> tuple[int, int]:
    """
    計算分支相對於 base 的 ahead/behind commit 數

    Args:
        branch: 分支名稱（短名稱，如 "feat/0.1.1-W9-002.1"）
        base: 基礎分支，預設 "main"

    Returns:
        tuple[int, int]: (ahead, behind)
            - ahead: branch 比 base 多幾個 commit
            - behind: base 比 branch 多幾個 commit

    Example:
        ahead, behind = get_worktree_ahead_behind("feat/0.1.1-W9-002.1", "main")
        # 如果 branch 領先 3 commit，落後 0 commit：(3, 0)
    """
    try:
        # 計算 branch 超前 base 的 commit 數
        ahead_result = run_git_command(["rev-list", "--count", f"{base}..{branch}"])
        ahead = int(ahead_result[1]) if ahead_result[0] else 0

        # 計算 branch 落後 base 的 commit 數
        behind_result = run_git_command(["rev-list", "--count", f"{branch}..{base}"])
        behind = int(behind_result[1]) if behind_result[0] else 0

        return (ahead, behind)
    except Exception:
        return (0, 0)


def get_worktree_uncommitted_count(worktree_path: str) -> int:
    """
    計算 worktree 中未 commit 的變更數

    Args:
        worktree_path: worktree 絕對路徑

    Returns:
        int: 未 commit 變更的行數

    Example:
        count = get_worktree_uncommitted_count("/path/to/ccsession-0.1.1-W9-002.1")
    """
    try:
        success, output = run_git_command(
            ["status", "--porcelain"],
            cwd=worktree_path
        )
        if not success:
            return 0

        lines = output.strip().split('\n') if output.strip() else []
        return len([line for line in lines if line])
    except Exception:
        return 0


# ===== 子命令函式 =====


def _cmd_create_dry_run(ticket_id: str, branch_name: str, worktree_path: str, base: str) -> int:
    """
    create 子命令的 dry-run 模式（#13 修復：從 cmd_create 拆分出來）

    Args:
        ticket_id: Ticket ID
        branch_name: 推導的分支名
        worktree_path: 推導的 worktree 路徑
        base: 基礎分支

    Returns:
        int: exit code (0)
    """
    git_cmd = ["worktree", "add", "-b", branch_name, worktree_path, base]
    print("[Dry Run] 將要執行的操作：")
    print()
    print(f"  git {' '.join(git_cmd)}")
    print()
    print("實際執行請移除 --dry-run 參數。")
    return 0


def _cmd_create_validate_and_execute(
    ticket_id: str,
    branch_name: str,
    worktree_path: str,
    base: str
) -> int:
    """
    create 子命令的實際執行邏輯（#13 修復：從 cmd_create 拆分出來）

    Args:
        ticket_id: Ticket ID
        branch_name: 推導的分支名
        worktree_path: 推導的 worktree 路徑
        base: 基礎分支

    Returns:
        int: exit code (0 成功，1 失敗)
    """
    # 驗證基礎分支存在
    if not check_branch_exists(base):
        print(f"[錯誤] 基礎分支不存在：{base}")
        print()
        print("請確認分支名稱，或省略 --base 參數使用預設的 main")
        return 1

    # 檢查分支已存在
    if check_branch_exists(branch_name):
        print(f"[錯誤] 分支已存在：{branch_name}")
        print()
        print("如需重新建立，請先刪除分支：")
        print(f"  git branch -d {branch_name}")
        return 1

    # 檢查 worktree 路徑已存在
    if os.path.exists(worktree_path):
        print(f"[錯誤] 目錄已存在：{worktree_path}")
        print()
        print("如需重新建立，請先移除目錄或使用其他 ticket-id")
        return 1

    # 構建 git 命令並執行
    git_cmd = ["worktree", "add", "-b", branch_name, worktree_path, base]
    success, output = run_git_command(git_cmd)
    if not success:
        print(f"[錯誤] 建立 worktree 失敗：{output}")
        return 1

    # 成功輸出
    print("正在建立 worktree...")
    print(f"  Ticket: {ticket_id}")
    print(f"  分支:   {branch_name}")
    print(f"  基礎:   {base}")
    print(f"  路徑:   {worktree_path}")
    print()
    print("建立成功。")
    print()
    print("下一步：")
    print(f"  cd {worktree_path}")
    return 0


def cmd_create(ticket_id: str, base: str = DEFAULT_BASE_BRANCH, dry_run: bool = False) -> int:
    """
    create 子命令 - 建立新 worktree

    Args:
        ticket_id: Ticket ID
        base: 基礎分支，預設 "main"
        dry_run: 如果為 True，只顯示操作不執行

    Returns:
        int: exit code (0 成功，1 失敗)
    """
    # Step 1: 驗證 Ticket ID 格式
    if not parse_ticket_id(ticket_id):
        print(f"[錯誤] 無效的 Ticket ID 格式：\"{ticket_id}\"")
        print()
        print("Ticket ID 格式應為 X.X.X-WN-NNN（如：0.1.1-W9-002.1）")
        return 1

    # Step 2: 推導分支名和 worktree 路徑
    branch_name = derive_branch_name(ticket_id)
    worktree_path = derive_worktree_path(ticket_id)

    # Step 3: 區分 dry-run 和實際執行
    if dry_run:
        return _cmd_create_dry_run(ticket_id, branch_name, worktree_path, base)
    else:
        return _cmd_create_validate_and_execute(ticket_id, branch_name, worktree_path, base)


def _collect_worktree_info(worktrees: list[dict]) -> list[dict]:
    """
    收集 worktree 資訊（#7 修復：從 cmd_status 拆分出來降低認知負擔）

    Args:
        worktrees: worktree 列表

    Returns:
        list[dict]: 包含顯示用資訊的字典列表
    """
    display_info = []
    for wt in worktrees:
        path = wt.get("path", "")
        branch = wt.get("branch", "")
        is_detached = wt.get("detached", False)

        # 檢查是否為主倉庫
        is_main = branch in PROTECTED_BRANCHES

        # #12 修復：處理 detached HEAD worktree
        if is_detached:
            ticket_label = "detached"
            ahead, behind = 0, 0
            uncommitted = get_worktree_uncommitted_count(path)
            is_main = False
        # 反推 Ticket ID 或標籤
        elif is_main:
            ticket_label = "主倉庫"
            ahead, behind = 0, 0
            uncommitted = get_worktree_uncommitted_count(path)
        else:
            ticket_label = extract_ticket_id_from_branch(branch)
            if ticket_label is None:
                ticket_label = "無法辨識"
            ahead, behind = get_worktree_ahead_behind(branch, "main")
            uncommitted = get_worktree_uncommitted_count(path)

        display_info.append({
            "label": ticket_label,
            "path": path,
            "branch": branch if not is_detached else "detached",
            "ahead": ahead,
            "behind": behind,
            "uncommitted": uncommitted,
            "is_main": is_main,
            "is_detached": is_detached
        })

    return display_info


def _print_worktree_status(display_info: list[dict]) -> None:
    """
    格式化輸出 worktree 狀態（#7 修復：從 cmd_status 拆分出來）

    Args:
        display_info: 包含顯示用資訊的字典列表
    """
    print(f"Worktree 狀態（共 {len(display_info)} 個）")
    print("━" * WORKTREE_STATUS_OUTPUT_WIDTH)
    print()

    for i, info in enumerate(display_info):
        print(f"[{info['label']}]")
        print(f"  路徑：   {info['path']}")
        print(f"  分支：   {info['branch']}")

        if not info['is_main']:
            # 格式化 ahead/behind 輸出（#1 修復：0 時不顯示 -0）
            ahead_str = f"+{info['ahead']}" if info['ahead'] > 0 else f"{info['ahead']}"
            behind_str = f"+{info['behind']}" if info['behind'] > 0 else f"{info['behind']}"
            print(f"  領先：   {ahead_str} commits ahead of main")
            print(f"  落後：   {behind_str} commits behind main")

        print(f"  變更：   {info['uncommitted']} 個未 commit")

        if i < len(display_info) - 1:
            print()


def _find_target_worktree(worktrees: list[dict], ticket_id: str) -> Optional[dict]:
    """
    在 worktree 列表中查詢特定 Ticket 對應的 worktree（#7 修復：從 cmd_status 拆分出來）

    Args:
        worktrees: worktree 列表
        ticket_id: 欲查詢的 Ticket ID

    Returns:
        dict | None: 找到的 worktree，或 None
    """
    for wt in worktrees:
        branch = wt.get("branch", "")
        extracted_id = extract_ticket_id_from_branch(branch)
        if extracted_id == ticket_id:
            return wt
    return None


def cmd_status(ticket_id: Optional[str] = None) -> int:
    """
    status 子命令 - 查看 worktree 狀態

    Args:
        ticket_id: 可選，指定查詢特定 Ticket

    Returns:
        int: exit code (0 成功，1 失敗)
    """
    # Step 1: 取得全部 worktree 列表
    worktrees = get_worktree_list()

    # Step 2: 如果指定 ticket_id，進行篩選
    if ticket_id is not None:
        target_worktree = _find_target_worktree(worktrees, ticket_id)

        if target_worktree is None:
            print(f"[錯誤] 找不到 Ticket {ticket_id} 對應的 worktree。")
            print()

            # 列出現有 worktree
            existing = []
            for wt in worktrees:
                branch = wt.get("branch", "")
                extracted_id = extract_ticket_id_from_branch(branch)
                if extracted_id:
                    existing.append(f"  - {extracted_id} ({branch})")

            if existing:
                print("目前存在的 worktree：")
                for item in existing:
                    print(item)
                print()

            print("建立此 Ticket 的 worktree：")
            print(f"  /worktree create {ticket_id}")
            return 1

        worktrees = [target_worktree]

    # Step 3: 如果無任何 worktree（除主倉庫外）
    if ticket_id is None and len(worktrees) <= 1:
        print("目前沒有任何 worktree（除主倉庫外）。")
        print()
        print("建立新的 worktree：")
        print("  /worktree create <ticket-id>")
        return 0

    # Step 4: 收集 worktree 資訊
    display_info = _collect_worktree_info(worktrees)

    # Step 5: 格式化輸出
    _print_worktree_status(display_info)

    return 0


# ===== 主程式入口 =====


def main():
    """主程式入口 - 支援 create 和 status 子命令"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Git Worktree 管理工具 - 從 Ticket ID 自動推導分支名和路徑"
    )

    subparsers = parser.add_subparsers(dest="command", help="子命令")

    # create 子命令
    create_parser = subparsers.add_parser(
        "create",
        help="建立新 worktree"
    )
    create_parser.add_argument(
        "ticket_id",
        help="Ticket ID (例如：0.1.1-W9-002.1)"
    )
    create_parser.add_argument(
        "--base",
        default="main",
        help="基礎分支，預設為 main"
    )
    create_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="只顯示操作，不執行"
    )

    # status 子命令
    status_parser = subparsers.add_parser(
        "status",
        help="查看 worktree 狀態"
    )
    status_parser.add_argument(
        "ticket_id",
        nargs="?",
        help="可選：指定查詢特定 Ticket ID"
    )

    args = parser.parse_args()

    if args.command == "create":
        return cmd_create(
            args.ticket_id,
            base=args.base,
            dry_run=args.dry_run
        )
    elif args.command == "status":
        return cmd_status(args.ticket_id)
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
