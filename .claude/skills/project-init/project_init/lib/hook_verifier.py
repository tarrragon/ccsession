"""Hook 系統和工具可用性驗證模組.

此模組驗證 UV、ripgrep 等工具的可用性，以及 Hook 系統的完整性。
"""

import fnmatch
import json
import py_compile
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


from .env_detector import detect_ripgrep, detect_uv


MINIMUM_UV_VERSION = "0.1.0"
MINIMUM_RIPGREP_VERSION = "13.0.0"


@dataclass
class ToolStatus:
    """工具狀態資訊."""

    available: bool
    """工具是否可用."""
    version: Optional[str]
    """工具版本字串。"""
    path: Optional[str]
    """工具執行檔路徑。"""
    error_message: Optional[str]
    """若不可用，提供錯誤訊息."""


@dataclass
class HookSystemStatus:
    """Hook 系統狀態資訊."""

    hooks_directory: Path
    """Hook 目錄路徑."""
    hook_count: int
    """找到的 Hook 檔案數量."""
    all_compilable: bool
    """所有 Hook 是否都能編譯通過."""
    errors: list[str]
    """編譯失敗的 Hook 清單."""


@dataclass
class HookCompletenessResult:
    """Hook 完整性檢查結果."""

    all_hooks: set[str]
    """掃描到的所有 Hook 檔案（排除 exclude list）."""
    registered_hooks: set[str]
    """在 settings.json 中已登記的 Hook 檔案."""
    unregistered_hooks: set[str]
    """未在 settings.json 中登記的 Hook 檔案。"""
    excluded_count: int
    """被排除在檢查外的 Hook 檔案數量。"""
    completeness_ok: bool
    """是否所有 Hook 都已登記。"""


def verify_uv_available() -> ToolStatus:
    """驗證 UV 工具是否可用且版本符合最低要求.

    Returns:
        ToolStatus: UV 工具狀態。
    """
    uv_info = detect_uv()

    if not uv_info.is_available:
        return ToolStatus(
            available=False,
            version=None,
            path=None,
            error_message="UV 工具未找到或無法執行。",
        )

    return ToolStatus(
        available=True,
        version=uv_info.version,
        path=uv_info.path,
        error_message=None,
    )


def verify_ripgrep_available() -> ToolStatus:
    """驗證 ripgrep 工具是否可用且版本符合最低要求.

    Returns:
        ToolStatus: ripgrep 工具狀態。
    """
    rg_info = detect_ripgrep()

    if not rg_info.is_available:
        return ToolStatus(
            available=False,
            version=None,
            path=None,
            error_message="ripgrep (rg) 工具未找到或無法執行。",
        )

    return ToolStatus(
        available=True,
        version=rg_info.version,
        path=rg_info.path,
        error_message=None,
    )


def verify_pep723_execution() -> ToolStatus:
    """驗證 PEP 723 腳本能否透過 UV 正常執行.

    測試執行一個最小的 inline script 來確認 `uv run` 能正常工作。

    Returns:
        ToolStatus: 執行狀態。
    """
    try:
        script = "print('PEP 723 test')"
        result = subprocess.run(
            ["uv", "run", "--", "python", "-c", script],
            capture_output=True,
            text=True,
            timeout=10,
        )

        if result.returncode == 0:
            return ToolStatus(
                available=True,
                version="PEP 723",
                path=None,
                error_message=None,
            )
        else:
            error_msg = result.stderr or result.stdout or "Unknown error"
            return ToolStatus(
                available=False,
                version=None,
                path=None,
                error_message=f"PEP 723 執行失敗: {error_msg}",
            )
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        return ToolStatus(
            available=False,
            version=None,
            path=None,
            error_message=f"PEP 723 驗證異常: {str(e)}",
        )


def verify_hooks_system(project_root: Path) -> HookSystemStatus:
    """驗證 Hook 系統是否完整且可編譯.

    掃描 .claude/hooks/ 目錄下所有 .py 檔案，嘗試編譯檢查語法。

    Args:
        project_root: 專案根目錄。

    Returns:
        HookSystemStatus: Hook 系統狀態。
    """
    hooks_dir = project_root / ".claude" / "hooks"

    if not hooks_dir.exists():
        return HookSystemStatus(
            hooks_directory=hooks_dir,
            hook_count=0,
            all_compilable=False,
            errors=["Hook 目錄不存在。"],
        )

    hook_files = list(hooks_dir.glob("*.py"))
    errors = []

    for hook_file in hook_files:
        try:
            py_compile.compile(str(hook_file), doraise=True)
        except py_compile.PyCompileError as e:
            errors.append(f"{hook_file.name}: {str(e)}")

    all_compilable = len(errors) == 0

    return HookSystemStatus(
        hooks_directory=hooks_dir,
        hook_count=len(hook_files),
        all_compilable=all_compilable,
        errors=errors,
    )


def _load_json_file(file_path: Path) -> Optional[dict]:
    """載入並解析 JSON 檔案.

    Args:
        file_path: JSON 檔案路徑。

    Returns:
        dict: 解析後的 JSON 物件，或 None 若檔案不存在或解析失敗。
    """
    if not file_path.exists():
        return None

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


def _get_exclude_patterns(exclude_list: Optional[dict]) -> tuple[set[str], set[str]]:
    """從 hook-exclude-list.json 提取要排除的檔案清單和模式.

    Args:
        exclude_list: 從 hook-exclude-list.json 解析的 dict，或 None。

    Returns:
        tuple[set[str], set[str]]: (確切檔名集合, 模式集合)
    """
    if exclude_list is None:
        # 預設排除清單
        exact_excludes = {
            "common_functions.py",
            "frontmatter_parser.py",
            "hook_utils.py",
            "markdown_formatter.py",
            "parse-test-json.py",
        }
        patterns = {"*-backup.py"}
        return exact_excludes, patterns

    exact_excludes = set(exclude_list.get("exclude", []))
    patterns = set(exclude_list.get("exclude_patterns", []))

    return exact_excludes, patterns


def _should_exclude_file(
    filename: str, exact_excludes: set[str], patterns: set[str]
) -> bool:
    """判斷檔案是否應被排除.

    Args:
        filename: 要檢查的檔名。
        exact_excludes: 確切檔名集合。
        patterns: 模式集合（支援 fnmatch）。

    Returns:
        bool: 是否應被排除。
    """
    if filename in exact_excludes:
        return True

    for pattern in patterns:
        if fnmatch.fnmatch(filename, pattern):
            return True

    return False


def _scan_hooks_directory(
    hooks_dir: Path, exact_excludes: set[str], patterns: set[str]
) -> set[str]:
    """掃描 .claude/hooks/ 目錄找到所有 .py 檔案（排除 exclude list）.

    Args:
        hooks_dir: Hook 目錄路徑。
        exact_excludes: 確切檔名集合（要排除的）。
        patterns: 模式集合（要排除的）。

    Returns:
        set[str]: Hook 檔名集合。
    """
    hook_files: set[str] = set()

    if not hooks_dir.exists():
        return hook_files

    for file_path in hooks_dir.glob("*.py"):
        filename = file_path.name

        if _should_exclude_file(filename, exact_excludes, patterns):
            continue

        hook_files.add(filename)

    return hook_files


def _extract_registered_hooks(settings: dict) -> set[str]:
    """從 settings.json 提取所有已登記的 Hook 檔名.

    掃描 hooks 配置中所有事件類型（PreToolUse、PostToolUse 等），
    從 command 欄位提取 .claude/hooks/ 後的檔名。

    Args:
        settings: settings.json 解析後的 dict。

    Returns:
        set[str]: 已登記的 Hook 檔名集合。
    """
    registered: set[str] = set()
    hooks_config = settings.get("hooks", {})

    for event_type, event_hooks in hooks_config.items():
        if isinstance(event_hooks, list):
            for hook_group in event_hooks:
                if isinstance(hook_group, dict):
                    for hook in hook_group.get("hooks", []):
                        if isinstance(hook, dict):
                            command = hook.get("command", "")
                            # 從 command 提取檔名
                            # e.g.: "$CLAUDE_PROJECT_DIR/.claude/hooks/hook-name.py" -> "hook-name.py"
                            if ".claude/hooks/" in command:
                                filename = command.split(".claude/hooks/")[-1]
                                # 移除尾部參數
                                filename = filename.split()[0] if filename else ""
                                if filename.endswith(".py"):
                                    registered.add(filename)

    return registered


def check_hook_completeness(project_root: Path) -> HookCompletenessResult:
    """檢查 Hook 完整性 — 驗證所有 .claude/hooks/*.py 都已在 settings.json 登記.

    掃描 .claude/hooks/ 目錄，與 settings.json 比對已登記的 Hook，
    回傳未登記的清單。

    Args:
        project_root: 專案根目錄。

    Returns:
        HookCompletenessResult: 完整性檢查結果。
    """
    hooks_dir = project_root / ".claude" / "hooks"
    settings_path = project_root / ".claude" / "settings.json"
    exclude_list_path = hooks_dir / "hook-exclude-list.json"

    # 載入設定檔
    settings = _load_json_file(settings_path)
    if settings is None:
        # settings.json 不存在，無法驗證
        return HookCompletenessResult(
            all_hooks=set(),
            registered_hooks=set(),
            unregistered_hooks=set(),
            excluded_count=0,
            completeness_ok=True,
        )

    exclude_list = _load_json_file(exclude_list_path)
    exact_excludes, patterns = _get_exclude_patterns(exclude_list)

    # 掃描 Hook 目錄
    all_hooks = _scan_hooks_directory(hooks_dir, exact_excludes, patterns)
    registered_hooks = _extract_registered_hooks(settings)

    # 計算未登記的 Hook
    unregistered_hooks = all_hooks - registered_hooks

    # 計算被排除的檔案數量
    excluded_count = sum(
        1
        for f in hooks_dir.glob("*.py")
        if _should_exclude_file(f.name, exact_excludes, patterns)
    )

    completeness_ok = len(unregistered_hooks) == 0

    return HookCompletenessResult(
        all_hooks=all_hooks,
        registered_hooks=registered_hooks,
        unregistered_hooks=unregistered_hooks,
        excluded_count=excluded_count,
        completeness_ok=completeness_ok,
    )
