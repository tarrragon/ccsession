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
    TICKET_QUERY_TIMEOUT,
    TICKET_COMPLETED_STATUS,
    CLEANUP_OUTPUT_WIDTH,
    BRANCH_FORCE_DELETE_FLAG,
)
from messages import MergeMessages, CleanupMessages, CommonMessages

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


# ===== merge 子命令相關函式 =====


def _query_ticket_status(ticket_id: str) -> Optional[str]:
    """
    查詢 Ticket 的 status 欄位

    透過 subprocess 呼叫 ticket track query，解析 status 欄位回傳。
    若 CLI 不可用或查詢失敗，回傳 None（呼叫端依 None 決定是否降級）。

    Args:
        ticket_id: Ticket ID

    Returns:
        str | None: Ticket 狀態字串（如 "completed"），或 None 表示查詢失敗
    """
    try:
        result = subprocess.run(
            ["ticket", "track", "query", ticket_id],
            capture_output=True,
            text=True,
            timeout=TICKET_QUERY_TIMEOUT
        )
        if result.returncode == 0:
            # 簡單解析：從輸出中找 "status: completed" 之類的行
            for line in result.stdout.split('\n'):
                if 'status' in line.lower():
                    # 嘗試提取狀態值
                    parts = line.split(':')
                    if len(parts) >= 2:
                        return parts[1].strip()
        return None
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        # 靜默降級：查詢失敗時不阻擋 merge 流程
        # 呼叫端會依 None 返回值降級為警告，允許繼續執行
        return None


def _is_branch_merged_to_base(branch: str, base: str = DEFAULT_BASE_BRANCH) -> bool:
    """
    判斷分支是否已合併到 base 分支

    使用 git branch --merged <base> 並檢查 branch 是否在結果中。

    Args:
        branch: 分支名稱
        base: 基礎分支，預設 "main"

    Returns:
        bool: True 表示已合併，False 表示未合併或無法判斷
    """
    success, output = run_git_command(["branch", "--merged", base])
    if not success:
        return False
    merged_branches = [b.strip() for b in output.split('\n')]
    return branch in merged_branches


def _is_branch_pushed(branch: str) -> bool:
    """
    判斷本地分支是否已 push 到 origin

    透過 git rev-parse --verify origin/<branch> 確認 origin 是否有對應分支。
    若有 origin 分支，再比較兩者的 HEAD commit 是否相同。

    Args:
        branch: 分支名稱（短名稱，不含 origin/ 前綴）

    Returns:
        bool: True 表示已 push（origin 存在且與本地同步），False 表示未 push
    """
    # 檢查 origin 分支是否存在
    success, _ = run_git_command(["rev-parse", "--verify", f"origin/{branch}"])
    if not success:
        return False

    # 比較本地和 remote 的 HEAD commit
    success_local, local_commit = run_git_command(["rev-parse", branch])
    success_remote, remote_commit = run_git_command(["rev-parse", f"origin/{branch}"])

    return success_local and success_remote and local_commit == remote_commit


def _merge_validate_ticket_status(ticket_id: str) -> tuple[bool, str]:
    """
    驗證 Ticket 狀態是否為 completed

    透過 ticket track query 查詢狀態，若 CLI 不可用則降級為警告。

    Args:
        ticket_id: Ticket ID

    Returns:
        tuple[bool, str]:
            - bool: True 表示可繼續（狀態為 completed 或查詢失敗降級）
            - str: 若 False，包含阻擋原因；若 True，可能含降級警告訊息
    """
    status = _query_ticket_status(ticket_id)

    if status is None:
        # 查詢失敗，降級為警告
        return True, MergeMessages.TICKET_STATUS_UNAVAILABLE

    if status.lower() == TICKET_COMPLETED_STATUS:
        return True, ""

    # Ticket 未完成，阻擋
    return False, MergeMessages.TICKET_NOT_COMPLETED.format(ticket_id=ticket_id, status=status)




def _merge_build_output(
    ticket_id: str,
    branch_name: str,
    ahead: int,
    behind: int,
    warnings: list[str]
) -> None:
    """
    輸出 git merge 指令和相關提示訊息

    Args:
        ticket_id: Ticket ID
        branch_name: 分支名稱（如 "feat/0.1.1-W9-002"）
        ahead: 分支領先 main 的 commit 數
        behind: 分支落後 main 的 commit 數
        warnings: 需要顯示的警告訊息列表（可為空）
    """
    print(MergeMessages.VERIFICATION_IN_PROGRESS)
    print()
    print(MergeMessages.VERIFICATION_TICKET_STATUS)
    print(MergeMessages.VERIFICATION_WORKING_TREE)
    print(f"  領先 main：{ahead} 個 commit")
    print(f"  落後 main：{behind} 個 commit")
    print()

    # 輸出任何警告
    for warning in warnings:
        print(warning)
        print()

    # 輸出 merge 指令
    print(MergeMessages.MERGE_COMMAND_HEADER)
    print()
    print(f"  git checkout main")
    print(f"  git merge --no-ff {branch_name}")
    print()
    print(MergeMessages.MERGE_COMMAND_HINT.format(ticket_id=ticket_id))


def _print_existing_worktrees() -> None:
    """
    格式化列出所有現有的 worktree（含 Ticket ID）

    遍歷所有 worktree，提取 Ticket ID 並輸出清單。
    主要用於錯誤訊息（找不到指定 Ticket）。
    """
    existing_worktrees = get_worktree_list()
    existing = []
    for wt in existing_worktrees:
        branch = wt.get("branch", "")
        extracted_id = extract_ticket_id_from_branch(branch)
        if extracted_id:
            existing.append(f"  - {extracted_id} ({branch})")

    if existing:
        print("目前存在的 worktree：")
        for item in existing:
            print(item)


def _find_worktree(ticket_id: str) -> Optional[dict]:
    """
    在 worktree 列表中查詢特定 Ticket 對應的 worktree

    Args:
        ticket_id: 欲查詢的 Ticket ID

    Returns:
        dict | None: 找到的 worktree，或 None
    """
    return _find_target_worktree(get_worktree_list(), ticket_id)


def cmd_merge(ticket_id: str) -> int:
    """
    merge 子命令 — 前置驗證並輸出 git merge 指令

    驗證 Ticket 狀態為 completed、working tree 乾淨、ahead/behind 狀態後，
    輸出 git merge --no-ff 指令供使用者執行（不自動執行 git merge）。

    Args:
        ticket_id: Ticket ID（如 "0.1.1-W9-002"）

    Returns:
        int: exit code（0 成功輸出指令，1 驗證失敗被阻擋）
    """
    # Step 1: 驗證 Ticket ID 格式
    if not is_valid_ticket_id(ticket_id):
        print(f"[錯誤] 無效的 Ticket ID 格式：\"{ticket_id}\"")
        print()
        print("Ticket ID 格式應為 X.X.X-WN-NNN（如：0.1.1-W9-002）")
        return 1

    # Step 2: 查詢對應的 worktree
    worktree = _find_worktree(ticket_id)
    if worktree is None:
        print(CommonMessages.WORKTREE_NOT_FOUND.format(ticket_id=ticket_id))
        print()
        # 列出現有 worktree
        _print_existing_worktrees()
        return 1

    # Step 3: 驗證 Ticket 狀態
    can_continue, msg = _merge_validate_ticket_status(ticket_id)
    if not can_continue:
        print(msg)
        return 1

    warnings = []
    if msg:
        # 降級警告，但可繼續
        warnings.append(msg)

    # Step 4: 檢查 working tree 乾淨
    is_clean, uncommitted = _check_working_tree_clean(worktree["path"])
    if not is_clean:
        print(MergeMessages.DIRTY_WORKING_TREE.format(count=uncommitted))
        return 1

    # Step 5: 計算 ahead/behind
    branch_name = worktree.get("branch", f"feat/{ticket_id}")
    ahead, behind = get_worktree_ahead_behind(branch_name, DEFAULT_BASE_BRANCH)

    # 檢查警告條件
    if ahead == 0:
        warnings.append(MergeMessages.NO_NEW_COMMITS.format(base=DEFAULT_BASE_BRANCH))

    if behind > 0:
        warnings.append(MergeMessages.BRANCH_BEHIND_BASE.format(base=DEFAULT_BASE_BRANCH, count=behind))

    # Step 6: 輸出指令
    _merge_build_output(ticket_id, branch_name, ahead, behind, warnings)

    return 0


# ===== cleanup 子命令相關函式 =====


def _check_working_tree_clean(worktree_path: str) -> tuple[bool, int]:
    """
    檢查 worktree 的 working tree 是否乾淨

    共用檢查函式，用於 merge 和 cleanup 子命令。

    Args:
        worktree_path: worktree 絕對路徑

    Returns:
        tuple[bool, int]:
            - bool: True 表示乾淨（無未 commit 變更），False 表示有變更
            - int: 未 commit 變更數量
    """
    uncommitted = get_worktree_uncommitted_count(worktree_path)
    return (uncommitted == 0, uncommitted)


def _cleanup_check_level1(worktree_path: str) -> tuple[bool, int]:
    """
    Level 1 閘門：檢查未 commit 變更（永不可繞過）

    Args:
        worktree_path: worktree 絕對路徑

    Returns:
        tuple[bool, int]:
            - bool: True 表示通過（無未 commit 變更）
            - int: 未 commit 變更數量
    """
    return _check_working_tree_clean(worktree_path)


def _cleanup_check_level2(branch: str) -> tuple[bool, str]:
    """
    Level 2 閘門：檢查未 push 狀態（可被 --force 略過）

    透過比較 branch 和 origin/branch 的 commit 差距判斷是否已 push。
    若 origin 無對應分支（尚未 push 過），視為未 push。

    Args:
        branch: 分支名稱（如 "feat/0.1.1-W9-002"）

    Returns:
        tuple[bool, str]:
            - bool: True 表示通過（已 push 或無 origin）
            - str: 若 False，包含警告說明訊息
    """
    if _is_branch_pushed(branch):
        return True, ""

    warning_msg = CleanupMessages.LEVEL2_WARNING.format(branch=branch)
    return False, warning_msg


def _cleanup_check_level3(branch: str, base: str = DEFAULT_BASE_BRANCH) -> tuple[bool, str]:
    """
    Level 3 閘門：檢查分支是否已合併到 base（可被 --force 略過）

    透過 git branch --merged 判斷分支是否已被合併。

    Args:
        branch: 分支名稱（如 "feat/0.1.1-W9-002"）
        base: 基礎分支，預設 "main"

    Returns:
        tuple[bool, str]:
            - bool: True 表示通過（已合併到 base）
            - str: 若 False，包含警告說明訊息
    """
    if _is_branch_merged_to_base(branch, base):
        return True, ""

    warning_msg = CleanupMessages.LEVEL3_WARNING.format(branch=branch, base=base)
    return False, warning_msg


def _cleanup_execute(worktree_path: str, branch: str) -> tuple[bool, str]:
    """
    執行 worktree 清理（移除 worktree 目錄和分支）

    依序執行：
    1. git worktree remove <path>
    2. git branch -d <branch>（-d 要求已合併，若失敗則提示 -D）

    Args:
        worktree_path: worktree 絕對路徑
        branch: 分支名稱

    Returns:
        tuple[bool, str]:
            - bool: True 表示 worktree 和分支均已清理
            - str: 結果說明（成功訊息或部分失敗提示）
    """
    # 移除 worktree
    success, output = run_git_command(["worktree", "remove", worktree_path])
    if not success:
        error_msg = CleanupMessages.REMOVE_FAILED.format(error=output)
        return False, error_msg

    # 刪除分支
    success, output = run_git_command(["branch", "-d", branch])
    if not success:
        partial_msg = CleanupMessages.BRANCH_DELETE_FAILED.format(
            branch=branch,
            force_flag=BRANCH_FORCE_DELETE_FLAG
        )
        return True, partial_msg  # 部分成功

    success_msg = CleanupMessages.CLEANUP_SUCCESS.format(path=worktree_path, branch=branch)
    return True, success_msg


def _cleanup_single(
    worktree: dict,
    ticket_id: str,
    force: bool
) -> int:
    """
    清理指定 worktree（精確模式核心邏輯）

    依序執行三閘門安全檢查，通過後執行 git worktree remove + git branch -d。

    Args:
        worktree: worktree 資訊字典（含 path, branch 等欄位）
        ticket_id: Ticket ID（用於錯誤訊息）
        force: 是否略過 Level 2/3 警告閘門

    Returns:
        int: exit code（0 成功，1 被閘門阻擋或執行失敗）
    """
    path = worktree.get("path", "")
    branch = worktree.get("branch", f"feat/{ticket_id}")

    print(f"正在清理 Ticket {ticket_id} 的 worktree...")
    print()

    # Level 1: 未 commit 檢查（永不可繞過）
    passed, uncommitted_count = _cleanup_check_level1(path)
    if not passed:
        print(CleanupMessages.LEVEL1_REJECTED.format(count=uncommitted_count))
        return 1

    print(f"  Level 1 檢查：通過（無未 commit 變更）")

    # Level 2: 未 push 檢查
    passed, warning_msg = _cleanup_check_level2(branch)
    if not passed:
        print(f"  Level 2 檢查：失敗")
        print()
        print(warning_msg)
        if not force:
            return 1
        print()
        print("[警告] 使用 --force 略過此警告，繼續清理")
    else:
        print(f"  Level 2 檢查：通過（已 push 到 origin）")

    # Level 3: 未合併檢查
    passed, warning_msg = _cleanup_check_level3(branch)
    if not passed:
        print(f"  Level 3 檢查：失敗")
        print()
        print(warning_msg)
        if not force:
            return 1
        print()
        print("[警告] 使用 --force 略過此警告，繼續清理")
    else:
        print(f"  Level 3 檢查：通過（已合併到 main）")

    print()

    # 執行清理
    success, result_msg = _cleanup_execute(path, branch)
    print(result_msg)

    return 0 if success else 1


def _cleanup_filter_feature_worktrees(worktrees: list[dict]) -> list[dict]:
    """
    篩選非保護分支的 worktree

    Args:
        worktrees: 完整 worktree 列表

    Returns:
        list[dict]: 只含 feature worktree 的列表
    """
    feature_worktrees = []
    for wt in worktrees:
        branch = wt.get("branch", "")
        if branch not in PROTECTED_BRANCHES and not wt.get("detached", False):
            feature_worktrees.append(wt)
    return feature_worktrees


def _cleanup_classify_worktrees(feature_worktrees: list[dict]) -> tuple[list[str], list[tuple], list[tuple]]:
    """
    三閘門分類 feature worktree

    依序執行 Level 1-3 檢查，將 worktree 分類為三組：
    - safe_to_clean: 已合併、乾淨
    - warnings: 未 push 或未合併
    - unsafe: 有未 commit 變更

    Args:
        feature_worktrees: feature worktree 列表

    Returns:
        tuple[list, list, list]: (safe_to_clean, warnings, unsafe)
    """
    safe_to_clean = []
    warnings = []
    unsafe = []

    for wt in feature_worktrees:
        path = wt.get("path", "")
        branch = wt.get("branch", "")
        ticket_id = extract_ticket_id_from_branch(branch)

        # Level 1 檢查
        passed_l1, uncommitted = _cleanup_check_level1(path)
        if not passed_l1:
            unsafe.append((ticket_id or branch, uncommitted))
            continue

        # Level 2 檢查
        passed_l2, _ = _cleanup_check_level2(branch)
        if not passed_l2:
            warnings.append((ticket_id or branch, branch, "未 push"))
            continue

        # Level 3 檢查
        passed_l3, _ = _cleanup_check_level3(branch)
        if not passed_l3:
            warnings.append((ticket_id or branch, branch, "未合併"))
            continue

        # 都通過
        safe_to_clean.append(ticket_id or branch)

    return safe_to_clean, warnings, unsafe


def _cleanup_print_scan_report(
    safe_to_clean: list[str],
    warnings: list[tuple],
    unsafe: list[tuple]
) -> None:
    """
    格式化輸出 cleanup 掃描報告

    Args:
        safe_to_clean: 建議清理的 ticket ID 清單
        warnings: 警告清單（ticket_id, branch, reason）
        unsafe: 不安全清單（ticket_id, uncommitted_count）
    """
    print(CleanupMessages.SCAN_HEADER)
    print("━" * CLEANUP_OUTPUT_WIDTH)
    print()

    # 建議清理
    if safe_to_clean:
        print(CleanupMessages.SCAN_SAFE_TO_CLEAN)
        for ticket_id in safe_to_clean:
            print(f"  - {ticket_id}")
            print(f"    {CleanupMessages.SCAN_CLEANUP_HINT.format(ticket_id=ticket_id)}")
        print()

    # 警告
    if warnings:
        print(CleanupMessages.SCAN_WARNING)
        for ticket_id, branch, reason in warnings:
            print(f"  - {ticket_id} ({branch})  [{reason}]")
            print(f"    {CleanupMessages.SCAN_FORCE_HINT.format(ticket_id=ticket_id)}")
        print()

    # 不安全
    if unsafe:
        print(CleanupMessages.SCAN_UNSAFE)
        for ticket_id, uncommitted in unsafe:
            print(f"  - {ticket_id}  [{uncommitted} 個未 commit 變更]")
            print("    請先 commit 後再清理。")
        print()


def _cleanup_scan_all() -> int:
    """
    掃描所有 worktree 並分類輸出建議（掃描模式）

    逐一評估每個 worktree 的安全狀態，輸出分類報告：
    - 建議清理（已合併、乾淨）
    - 警告（未 push 或未合併）
    - 不安全（有未 commit 變更）

    Returns:
        int: exit code（永遠返回 0，僅輸出資訊）
    """
    worktrees = get_worktree_list()

    # 篩選非主倉庫的 worktree
    feature_worktrees = _cleanup_filter_feature_worktrees(worktrees)

    if not feature_worktrees:
        print(CleanupMessages.SCAN_NO_CLEANUP_NEEDED)
        return 0

    # 分類 worktree
    safe_to_clean, warnings, unsafe = _cleanup_classify_worktrees(feature_worktrees)

    # 輸出報告
    _cleanup_print_scan_report(safe_to_clean, warnings, unsafe)

    return 0


def cmd_cleanup(ticket_id: Optional[str] = None, force: bool = False) -> int:
    """
    cleanup 子命令 — 三閘門安全清理 worktree

    無參數時執行掃描模式，列出可清理和需注意的 worktree。
    有 ticket_id 時執行精確模式，清理指定 worktree。
    --force 略過 Level 2 和 Level 3 警告（但 Level 1 永不可繞過）。

    Args:
        ticket_id: 可選，指定清理特定 Ticket 的 worktree
        force: 若 True，略過警告閘門直接執行

    Returns:
        int: exit code（0 成功/掃描完成，1 失敗/被阻擋）
    """
    # 無參數：掃描模式
    if ticket_id is None:
        return _cleanup_scan_all()

    # 有參數：精確模式

    # Step 1: 驗證 Ticket ID 格式
    if not is_valid_ticket_id(ticket_id):
        print(f"[錯誤] 無效的 Ticket ID 格式：\"{ticket_id}\"")
        print()
        print("Ticket ID 格式應為 X.X.X-WN-NNN（如：0.1.1-W9-002）")
        return 1

    # Step 2: 查詢對應的 worktree
    worktree = _find_worktree(ticket_id)
    if worktree is None:
        print(CommonMessages.WORKTREE_NOT_FOUND.format(ticket_id=ticket_id))
        print()
        # 列出現有 worktree
        _print_existing_worktrees()
        return 1

    # Step 3: 執行清理
    return _cleanup_single(worktree, ticket_id, force)


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

    # merge 子命令
    merge_parser = subparsers.add_parser(
        "merge",
        help="前置驗證並輸出 git merge 指令"
    )
    merge_parser.add_argument(
        "ticket_id",
        help="Ticket ID (例如：0.1.1-W9-002)"
    )

    # cleanup 子命令
    cleanup_parser = subparsers.add_parser(
        "cleanup",
        help="三閘門安全清理 worktree"
    )
    cleanup_parser.add_argument(
        "ticket_id",
        nargs="?",
        help="可選：指定清理特定 Ticket（若省略則掃描所有 worktree）"
    )
    cleanup_parser.add_argument(
        "--force",
        action="store_true",
        help="略過 Level 2（未 push）和 Level 3（未合併）警告（Level 1 永不可繞過）"
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
    elif args.command == "merge":
        return cmd_merge(args.ticket_id)
    elif args.command == "cleanup":
        return cmd_cleanup(args.ticket_id, force=args.force)
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
