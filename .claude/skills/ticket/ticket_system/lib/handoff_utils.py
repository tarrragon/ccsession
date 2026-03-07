"""
Handoff 共用判斷函式模組

封裝 resume.py 和 handoff_gc.py 共用的 stale handoff 判斷邏輯。
消除跨模組私有函式引用，遵循模組封裝原則。
"""

from typing import Optional

from ticket_system.lib.constants import (
    STATUS_COMPLETED,
    STATUS_IN_PROGRESS,
    TASK_CHAIN_DIRECTION_TYPES,
)
from ticket_system.lib.ticket_ops import load_and_validate_ticket

# 所有已知的 direction 值
_KNOWN_DIRECTION_VALUES = {"context-refresh", "auto"} | set(TASK_CHAIN_DIRECTION_TYPES)


def is_ticket_completed(ticket_id: str) -> bool:
    """
    檢查 Ticket 是否已 completed。

    從 ticket_id 提取版本後載入 ticket 檢查狀態。
    若無法載入（不存在或格式錯誤），返回 False（保守策略：不確定時顯示）。

    Args:
        ticket_id: Ticket ID，格式如 "0.31.1-W5-004"

    Returns:
        bool: True 表示已完成，False 表示未完成或無法判斷
    """
    try:
        # 從 ticket_id 提取版本（前三個數字段）
        parts = ticket_id.split("-")
        if len(parts) < 3:
            return False
        version = parts[0]  # "0.31.1"

        ticket, error = load_and_validate_ticket(version, ticket_id, auto_print_error=False)
        if error:
            return False

        return ticket.get("status") == STATUS_COMPLETED
    except Exception:
        return False  # 保守策略：無法判斷時顯示


def is_task_chain_direction(direction: str) -> bool:
    """
    判斷 handoff 的 direction 是否為任務鏈類型。

    任務鏈 direction（to-sibling、to-parent、to-child）中，
    來源 ticket completed 是預期狀態（先 complete 再 handoff 到下一任務），
    不應被過濾為 stale。

    格式：direction 格式可為 "to-sibling:target_id" 或 "to-sibling" 等，
    使用 split(":") 提取第一段來判斷。

    Args:
        direction: Handoff direction 字符串，可能為 "to-sibling", "to-sibling:xxx", etc.

    Returns:
        bool: True 表示為任務鏈類型，False 表示為其他類型（context-refresh 等）
    """
    if not direction:
        return False

    # 提取 direction type（split ":" 取首段）
    direction_type = direction.split(":")[0]

    return direction_type in TASK_CHAIN_DIRECTION_TYPES


def is_ticket_in_progress_or_completed(ticket_id: str) -> bool:
    """
    檢查 Ticket 是否已 in_progress 或 completed。

    用於判斷任務鏈 handoff 的目標 ticket 是否已啟動。
    若目標已啟動，表示此 handoff 已被接手，應過濾為 stale。

    若無法載入（不存在或格式錯誤），返回 False（保守策略：不確定時顯示）。

    Args:
        ticket_id: Ticket ID，格式如 "0.31.1-W5-004"

    Returns:
        bool: True 表示已啟動（in_progress 或 completed），False 表示未啟動或無法判斷
    """
    try:
        parts = ticket_id.split("-")
        if len(parts) < 3:
            return False
        version = parts[0]

        ticket, error = load_and_validate_ticket(version, ticket_id, auto_print_error=False)
        if error:
            return False

        return ticket.get("status") in (STATUS_IN_PROGRESS, STATUS_COMPLETED)
    except Exception:
        return False  # 保守策略：無法判斷時顯示


def extract_direction_target_id(direction: str) -> Optional[str]:
    """
    從 direction 字串提取 target_id。

    格式：direction 可為 "type:target_id"（含目標）或 "type"（無目標）。
    - "to-sibling:0.1.0-W9-002" → "0.1.0-W9-002"
    - "to-parent" → None
    - "context-refresh" → None

    Args:
        direction: Handoff direction 字符串

    Returns:
        Optional[str]: target_id 若存在且非空，否則 None
    """
    parts = direction.split(":", 1)
    if len(parts) > 1 and parts[1]:
        return parts[1]
    return None


def is_valid_direction(direction: str) -> bool:
    """
    驗證 handoff 的 direction 是否為已知類型。

    已知 direction 值（不含後綴）：to-sibling、to-parent、to-child、context-refresh、auto
    支援的格式：
    - "to-sibling"、"to-sibling:target_id"
    - "to-parent"、"to-parent:target_id"
    - "to-child"、"to-child:target_id"
    - "context-refresh"
    - "auto"

    Args:
        direction: Handoff direction 字符串

    Returns:
        bool: True 表示為已知 direction，False 表示未知
    """
    if not direction:
        return False

    # 提取 direction type（split ":" 取首段，以支援 "to-sibling:target_id" 格式）
    direction_type = direction.split(":")[0]

    return direction_type in _KNOWN_DIRECTION_VALUES
