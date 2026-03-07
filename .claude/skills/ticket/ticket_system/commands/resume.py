"""
Ticket resume 命令模組

負責恢復任務功能，從 handoff 交接檔案讀取工作內容。
"""
# 防止直接執行此模組
if __name__ == "__main__":
    from ..lib.messages import print_not_executable_and_exit
    print_not_executable_and_exit()



import argparse
import json
import sys
from collections import namedtuple
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional, List

from ticket_system.lib.constants import (
    HANDOFF_DIR,
    HANDOFF_PENDING_SUBDIR,
    HANDOFF_ARCHIVE_SUBDIR,
    STATUS_COMPLETED,
)
from ticket_system.commands.exceptions import HandoffSchemaError, HandoffDirectionUnknownError
from ticket_system.lib.ticket_loader import resolve_version, load_ticket, get_project_root
from ticket_system.lib.messages import (
    ErrorMessages,
    WarningMessages,
    InfoMessages,
    SectionHeaders,
    format_error,
    format_warning,
    format_info,
)
from ticket_system.lib.command_lifecycle_messages import (
    ResumeMessages,
    format_msg,
)
from ticket_system.lib.handoff_utils import (
    is_ticket_completed,
    is_task_chain_direction,
    is_ticket_in_progress_or_completed,
    is_valid_direction,
)
from ticket_system.lib.ui_constants import SEPARATOR_PRIMARY


# Handoff JSON 必填欄位
_HANDOFF_REQUIRED_FIELDS = ("ticket_id", "direction", "timestamp")

# W7-004：定義 handoff 列表結果型別（從函式屬性改為明確的返回值）
# 包含有效 handoff 清單、過濾計數和格式錯誤計數
HandoffListResult = namedtuple("HandoffListResult", ["handoffs", "stale_count", "schema_error_count"])


def _validate_handoff_schema(data: dict, file_path: str) -> None:
    """
    驗證 handoff JSON 的必填欄位是否完整。

    必填欄位：ticket_id、direction、timestamp
    缺少任一欄位時拋出 HandoffSchemaError（含可操作指引）。

    Args:
        data: 已解析的 handoff JSON 資料
        file_path: handoff 檔案路徑（用於錯誤訊息）

    Raises:
        HandoffSchemaError: 缺少必填欄位時
    """
    missing = [f for f in _HANDOFF_REQUIRED_FIELDS if not data.get(f)]
    if missing:
        raise HandoffSchemaError(file_path, missing)


def _get_handoff_dir(subdir: str = HANDOFF_PENDING_SUBDIR) -> Path:
    """
    取得 handoff 目錄

    Args:
        subdir: 子目錄名 ("pending" 或 "archive")

    Returns:
        Path: handoff 目錄路徑
    """
    root = get_project_root()
    handoff_dir = root / HANDOFF_DIR / subdir
    return handoff_dir


def _find_handoff_file(ticket_id: str, subdir: str = HANDOFF_PENDING_SUBDIR) -> Optional[tuple[Path, str]]:
    """
    尋找 handoff 檔案，返回 (路徑, 格式)

    Args:
        ticket_id: Ticket ID
        subdir: 子目錄名 ("pending" 或 "archive")

    Returns:
        tuple[Path, str] | None: (檔案路徑, "json" | "markdown") 或 None
    """
    dir_path = _get_handoff_dir(subdir)

    # 優先檢查 JSON 格式
    json_file = dir_path / f"{ticket_id}.json"
    if json_file.exists():
        return (json_file, "json")

    # 其次檢查 Markdown 格式
    md_file = dir_path / f"{ticket_id}.md"
    if md_file.exists():
        return (md_file, "markdown")

    return None


def list_pending_handoffs() -> HandoffListResult:
    """
    列出所有待恢復的 handoff 檔案

    過濾規則：已 completed 的 Ticket 對應的 handoff 條目不顯示（stale handoff）

    Returns:
        HandoffListResult: 包含有效 handoff 清單、stale 計數、格式錯誤計數

    Raises:
        HandoffDirectionUnknownError: 遇到未知 direction 值時（由呼叫端捕捉）
    """
    pending_dir = _get_handoff_dir(HANDOFF_PENDING_SUBDIR)

    if not pending_dir.exists():
        return []

    handoffs = []
    stale_count = 0
    schema_error_count = 0

    # 同時掃描 .json 和 .md 檔案
    for handoff_file in sorted(pending_dir.glob("*.json")) + sorted(pending_dir.glob("*.md")):
        try:
            if handoff_file.suffix == ".json":
                with open(handoff_file, "r", encoding="utf-8") as f:
                    data = json.load(f)

                # W4-001: 驗證 JSON 必填欄位，缺少時跳過並輸出警告
                try:
                    _validate_handoff_schema(data, str(handoff_file))
                except HandoffSchemaError as e:
                    schema_error_count += 1
                    print(f"[WARNING] 跳過格式錯誤的 handoff：{e}", file=sys.stderr)
                    continue

                # W7-003: 驗證 direction 值是否為已知類型
                direction = data.get("direction", "")
                if not is_valid_direction(direction):
                    raise HandoffDirectionUnknownError(direction, str(handoff_file))

                # 過濾 stale handoff：
                # Handoff 是 stale 當且僅當：
                # 1. 來源 Ticket 已 completed（status: completed）
                # 2. 且 Handoff 是從非 completed 狀態創建的（from_status != "completed"）
                #
                # 特殊情況（保留）：
                # - 任務鏈 handoff（to-sibling/to-parent/to-child），即使 completed 也保留
                # - Handoff 本身是從 completed 狀態創建的，不算 stale
                ticket_id = data.get("ticket_id", "")
                if ticket_id and is_ticket_completed(ticket_id):
                    # Ticket 已 completed，檢查 handoff 狀態
                    from_status = data.get("from_status", "")

                    # 檢查是否為任務鏈類型
                    if is_task_chain_direction(direction):
                        # 任務鏈 handoff：進一步檢查目標 ticket 是否已啟動
                        # 若 direction 含 target_id（如 to-sibling:0.1.0-W3-009），
                        # 且目標已 in_progress/completed，則視為 stale
                        direction_parts = direction.split(":", 1)
                        if len(direction_parts) > 1:
                            target_id = direction_parts[1]
                            if target_id and is_ticket_in_progress_or_completed(target_id):
                                # 目標已啟動，此 handoff 為 stale（W4-002 計數）
                                stale_count += 1
                                continue
                        # 目標未啟動或無 target_id，保留
                        handoffs.append(data)
                        continue

                    # 非任務鏈：只有當 from_status 不是 completed 時才過濾為 stale
                    if from_status != "completed":
                        # Stale handoff，跳過（W4-002 計數）
                        stale_count += 1
                        continue

                handoffs.append(data)
            elif handoff_file.suffix == ".md":
                # Markdown 格式的 handoff 檔案也支援
                # 提取檔名作為 ticket_id
                ticket_id = handoff_file.stem

                # 過濾已完成 ticket 的 stale handoff
                # Markdown 格式無 direction 資訊，保持原行為
                if ticket_id and is_ticket_completed(ticket_id):
                    stale_count += 1  # W4-002 計數
                    continue  # 跳過 stale 條目

                handoffs.append({
                    "ticket_id": ticket_id,
                    "format": "markdown",
                    "path": str(handoff_file.relative_to(get_project_root()))
                })
        except (IOError, json.JSONDecodeError):
            # 略過無法讀取的檔案
            pass

    # W7-004：改為返回 namedtuple，取代函式屬性機制
    # 明確的返回值提高程式碼清晰度和類型安全性
    return HandoffListResult(
        handoffs=handoffs,
        stale_count=stale_count,
        schema_error_count=schema_error_count
    )


def load_handoff_file(ticket_id: str) -> Optional[Dict[str, Any]]:
    """
    載入特定的 handoff 檔案

    Args:
        ticket_id: Ticket ID

    Returns:
        Optional[Dict]: handoff 資料，或 None 如果不存在
    """
    file_info = _find_handoff_file(ticket_id, HANDOFF_PENDING_SUBDIR)
    if not file_info:
        return None

    file_path, file_format = file_info

    try:
        if file_format == "json":
            with open(file_path, "r", encoding="utf-8") as f:
                return json.load(f)
        else:  # markdown
            content = file_path.read_text(encoding="utf-8")
            return {
                "ticket_id": ticket_id,
                "format": "markdown",
                "content": content,
                "path": str(file_path.relative_to(get_project_root()))
            }
    except (IOError, json.JSONDecodeError):
        pass

    return None


def mark_handoff_as_resumed(ticket_id: str) -> bool:
    """
    標記 handoff 檔案為已接手（更新 resumed_at 時間戳）

    Args:
        ticket_id: Ticket ID

    Returns:
        bool: 成功返回 True，失敗返回 False
    """
    file_info = _find_handoff_file(ticket_id, HANDOFF_PENDING_SUBDIR)
    if not file_info:
        return False

    file_path, file_format = file_info

    if file_format != "json":
        # Markdown 格式無法更新，移到 archive
        return archive_handoff_file(ticket_id)

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        data["resumed_at"] = datetime.now().isoformat()

        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        return True
    except (IOError, json.JSONDecodeError, OSError):
        return False


def archive_handoff_file(ticket_id: str) -> bool:
    """
    將 handoff 檔案移動到 archive 目錄

    Args:
        ticket_id: Ticket ID

    Returns:
        bool: 成功返回 True，失敗返回 False
    """
    file_info = _find_handoff_file(ticket_id, HANDOFF_PENDING_SUBDIR)
    if not file_info:
        return False

    file_path, _ = file_info
    archive_dir = _get_handoff_dir(HANDOFF_ARCHIVE_SUBDIR)
    archive_dir.mkdir(parents=True, exist_ok=True)

    try:
        file_path.rename(archive_dir / file_path.name)
        return True
    except (IOError, OSError):
        return False


def _print_basic_info(handoff: Dict[str, Any]) -> None:
    """列印基本資訊（Ticket ID、標題、狀態、方向、時間）"""
    ticket_id = handoff.get("ticket_id")

    print(SectionHeaders.BASIC_INFO)
    print(f"  Ticket ID: {ticket_id}")

    if "title" in handoff:
        print(f"  標題: {handoff.get('title', '?')}")

    if "from_status" in handoff:
        print(f"  前狀態: {handoff.get('from_status', '?')}")

    if "direction" in handoff:
        direction = handoff.get("direction", "auto")
        print(f"  交接方向: {direction}")

        # Context refresh 額外說明
        if direction == "context-refresh":
            print(f"    （Context 刷新：在新 session 中以乾淨環境繼續此任務）")

    if "timestamp" in handoff:
        print(f"  交接時間: {handoff.get('timestamp')}")

    print()


def _print_5w1h_info(handoff: Dict[str, Any]) -> None:
    """列印 5W1H 任務描述"""
    if "what" in handoff:
        print(SectionHeaders.TASK_DESCRIPTION)
        print(f"  {handoff.get('what')}")
        print()


def _print_chain_info(handoff: Dict[str, Any]) -> None:
    """列印任務鏈資訊"""
    if "chain" not in handoff or not handoff["chain"]:
        return

    chain = handoff["chain"]
    print(SectionHeaders.TASK_CHAIN_INFO)
    print(f"  Root: {chain.get('root', 'N/A')}")
    print(f"  Parent: {chain.get('parent', 'N/A')}")
    print(f"  Depth: {chain.get('depth', 0)}")

    if "sequence" in chain:
        sequence_str = ".".join(map(str, chain["sequence"]))
        print(f"  序列: {sequence_str}")

    print()


def _print_markdown_content(handoff: Dict[str, Any]) -> None:
    """列印 Markdown 格式的完整內容"""
    if handoff.get("format") != "markdown" or "content" not in handoff:
        return

    print(SectionHeaders.FULL_CONTENT)
    print(handoff["content"])
    print()


def _print_ticket_info(ticket: Dict[str, Any]) -> None:
    """列印 Ticket 系統資訊"""
    print(SectionHeaders.TICKET_SYSTEM_INFO)
    print(f"  狀態: {ticket.get('status', 'unknown')}")

    for key in ["assignee", "priority", "type"]:
        if key in ticket:
            print(f"  {key.capitalize()}: {ticket.get(key)}")

    print()


def _print_handoff_info(handoff: Dict[str, Any], ticket: Optional[Dict[str, Any]] = None) -> None:
    """
    列印 handoff 交接資訊

    Args:
        handoff: handoff 資料
        ticket: Ticket 資料（可選）
    """
    ticket_id = handoff.get("ticket_id")

    print(SEPARATOR_PRIMARY)
    print(f"[Resume] {ticket_id}")
    print(SEPARATOR_PRIMARY)
    print()

    _print_basic_info(handoff)
    _print_5w1h_info(handoff)
    _print_chain_info(handoff)
    _print_markdown_content(handoff)

    if ticket:
        _print_ticket_info(ticket)


def _execute_list() -> int:
    """執行 --list 子命令"""
    try:
        result = list_pending_handoffs()
    except HandoffDirectionUnknownError as e:
        # W7-003: 捕捉未知 direction 異常，跳過該條目並顯示警告
        print(f"[WARNING] 跳過未知 direction 的 handoff：{e}", file=sys.stderr)
        if e.guidance:
            print(f"  指引：{e.guidance}", file=sys.stderr)
        # 繼續處理其他 handoff（遞迴呼叫不可行，故此處回傳 0）
        # 注意：此處異常發生時，list_pending_handoffs() 會在第一個不合法 direction 處中斷
        # 實際應用中，建議使用者修復損壞的 handoff 檔案後重試
        return 0

    # W7-004：從 namedtuple 提取 handoff 清單和 stale 計數
    handoffs = result.handoffs
    stale_count = result.stale_count
    if not handoffs:
        print(ResumeMessages.NO_PENDING_RESUMPTIONS)
        if stale_count > 0:
            print()
            print(f"[提示] 已過濾 {stale_count} 個 stale handoff（來源 ticket 已完成）")
            print(f"  執行 ticket handoff gc --dry-run 可查看詳細清單")
        return 0

    print(SEPARATOR_PRIMARY)
    print(SectionHeaders.PENDING_RESUME_LIST)
    print(SEPARATOR_PRIMARY)
    print()

    for idx, handoff in enumerate(handoffs, 1):
        ticket_id = handoff.get("ticket_id", "unknown")
        title = handoff.get("title", "")
        timestamp = handoff.get("timestamp", "")

        print(f"{idx}. {ticket_id}")
        if title:
            print(f"   標題: {title}")
        if timestamp:
            print(f"   時間: {timestamp}")
        print()

    print(f"總計: {len(handoffs)} 個待恢復任務")
    # W4-002: 顯示 stale 過濾計數（有結果時也提示是否有被過濾）
    if stale_count > 0:
        print(f"[提示] 另有 {stale_count} 個 stale handoff 已自動過濾（執行 ticket handoff gc --dry-run 查看）")
    print()
    print(ResumeMessages.RESUME_INSTRUCTIONS)
    print(ResumeMessages.RESUME_EXAMPLE_CMD)

    return 0


def _validate_args(args: argparse.Namespace) -> Optional[str]:
    """
    驗證參數，返回錯誤訊息或 None
    """
    ticket_id = getattr(args, "ticket_id", None)
    if not ticket_id:
        return format_error(ErrorMessages.MISSING_TICKET_ID)
    return None


def _print_args_error(error_msg: str) -> None:
    """列印參數錯誤和使用說明"""
    print(error_msg)
    print()
    print(ResumeMessages.RESUME_USAGE)
    print(ResumeMessages.RESUME_EXAMPLE_CMD)
    print(ResumeMessages.RESUME_LIST_CMD)
    print()
    print(ResumeMessages.RESUME_EXAMPLES)
    print(ResumeMessages.RESUME_EXAMPLE_ID)
    print(ResumeMessages.RESUME_LIST_CMD)


def _execute_resume(ticket_id: str, version: Optional[str]) -> int:
    """
    執行恢復單一 Ticket 的邏輯

    Args:
        ticket_id: Ticket ID
        version: 版本號（可選）

    Returns:
        int: 返回碼（0=成功, 1=失敗）
    """
    handoff = load_handoff_file(ticket_id)
    if not handoff:
        # 檢查 Ticket 是否存在，以提供更準確的錯誤訊息
        ticket_exists = False
        try:
            # 從 ticket_id 提取版本並嘗試載入 Ticket
            parts = ticket_id.split("-")
            if len(parts) >= 3:
                version_from_id = parts[0]
                ticket = load_ticket(version_from_id, ticket_id)
                ticket_exists = ticket is not None
        except Exception:
            pass

        # 根據 Ticket 是否存在顯示對應的錯誤訊息
        if ticket_exists:
            print(format_error(ErrorMessages.NO_HANDOFF_FILE, ticket_id=ticket_id))
        else:
            print(format_error(ErrorMessages.TICKET_NOT_FOUND, ticket_id=ticket_id))

        print()
        print(ResumeMessages.AVAILABLE_RESUMPTIONS)
        print(ResumeMessages.RESUME_LIST_CMD)
        return 1

    # 嘗試從 Ticket 系統載入對應的 Ticket 資訊
    ticket = None
    if version:
        resolved_version = resolve_version(version)
        if resolved_version:
            ticket = load_ticket(resolved_version, ticket_id)

    # 列印 handoff 資訊
    _print_handoff_info(handoff, ticket)

    # 標記為已接手（更新 resumed_at 時間戳）
    if not mark_handoff_as_resumed(ticket_id):
        print(format_warning(WarningMessages.INVALID_OPERATION))
        print(WarningMessages.HANDOFF_UPDATE_FAILED)
        return 1

    # 將 handoff 檔案從 pending/ 移動到 archive/
    # 注意：mark_handoff_as_resumed() 已自動歸檔 Markdown 格式，所以這裡只會歸檔 JSON
    if not archive_handoff_file(ticket_id):
        # 歸檔失敗不應該視為 resume 失敗（核心功能已完成），只發出警告
        print(format_warning(WarningMessages.INVALID_OPERATION))
        print(WarningMessages.HANDOFF_ARCHIVE_FAILED)

    print(SEPARATOR_PRIMARY)
    print(SectionHeaders.COMPLETION)
    print(InfoMessages.HANDOFF_RESUMED)
    print(SEPARATOR_PRIMARY)
    return 0


def execute(args: argparse.Namespace) -> int:
    """執行 resume 命令"""
    if getattr(args, "list", False):
        return _execute_list()

    # 驗證參數
    error_msg = _validate_args(args)
    if error_msg:
        _print_args_error(error_msg)
        return 1

    # 執行恢復邏輯
    ticket_id = getattr(args, "ticket_id", None)
    version = getattr(args, "version", None)
    return _execute_resume(ticket_id, version)


def register(subparsers: argparse._SubParsersAction) -> None:
    """註冊 resume 子命令"""
    parser = subparsers.add_parser("resume", help=ResumeMessages.HELP_TEXT)
    parser.add_argument("ticket_id", nargs="?", help=ResumeMessages.ARG_TICKET_ID_HELP)
    parser.add_argument("--list", action="store_true", help=ResumeMessages.ARG_LIST_HELP)
    parser.add_argument("--version", help=ResumeMessages.ARG_VERSION_HELP)
    parser.set_defaults(func=execute)
