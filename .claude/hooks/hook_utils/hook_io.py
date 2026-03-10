#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Hook I/O 操作模組

提供 git 命令執行、stdin JSON 讀取和資料提取等 I/O 相關功能。

核心 API：
- run_git(args, cwd, timeout, logger)
- read_json_from_stdin(logger)
- extract_tool_input(input_data, logger)
- extract_tool_response(input_data, logger)
"""

import json
import logging
import subprocess
import sys
from typing import List, Optional


def run_git(
    args: List[str],
    cwd: "str | None" = None,
    timeout: int = 5,
    logger: "logging.Logger | None" = None,
) -> "str | None":
    """執行 git 命令並回傳 stdout

    Args:
        args: git 子命令和參數，如 ["log", "-1", "--format=%ct"]
        cwd: 工作目錄（預設為當前目錄）
        timeout: 執行超時秒數（預設 5）
        logger: 可選日誌物件，失敗時記錄 warning

    Returns:
        stdout 輸出（stripped），或 None 若執行失敗
    """
    try:
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            cwd=cwd,
            timeout=timeout,
        )
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            if logger:
                logger.warning("git 命令失敗: {} (exit code: {})".format(
                    " ".join(args), result.returncode
                ))
            return None
    except subprocess.TimeoutExpired:
        if logger:
            logger.warning("git 命令超時: {}".format(" ".join(args)))
        return None
    except FileNotFoundError:
        if logger:
            logger.warning("git 命令未找到")
        return None
    except OSError as e:
        if logger:
            logger.warning("執行 git 命令失敗: {}".format(e))
        return None


def read_json_from_stdin(logger: logging.Logger) -> Optional[dict]:
    """從 stdin 讀取 JSON 輸入

    處理三種情況：
    1. 空輸入（SessionStart 等事件無輸入）
    2. JSON 解析失敗
    3. 有效的 JSON 物件

    Args:
        logger: Logger 實例

    Returns:
        dict: 解析後的 JSON，或 None（空輸入或解析失敗）
    """
    try:
        input_text = sys.stdin.read().strip()

        # 空輸入：直接返回 None
        if not input_text:
            return None

        # 解析 JSON
        return json.loads(input_text)

    except json.JSONDecodeError as e:
        logger.error("JSON 解析錯誤: {}".format(e))
        return None
    except Exception as e:
        logger.error("讀取 stdin 失敗: {}".format(e))
        return None


def extract_tool_input(
    input_data: "dict | None",
    logger: "logging.Logger | None" = None
) -> dict:
    """安全提取 input_data 中的 tool_input 欄位

    處理三種情況：
    1. input_data 為 None 或空值 → 返回 {}
    2. tool_input 欄位缺失或為 None → 返回 {}
    3. tool_input 為有效的 dict → 返回該 dict

    Args:
        input_data: Hook 輸入資料（dict 或 None）
        logger: 可選 Logger 實例，用於記錄詳細資訊

    Returns:
        dict: 提取出的 tool_input（始終返回 dict，無欄位時返回空 dict）

    Examples:
        >>> extract_tool_input({"tool_input": {"file_path": "test.py"}})
        {'file_path': 'test.py'}

        >>> extract_tool_input({"other": "value"})
        {}

        >>> extract_tool_input(None)
        {}
    """
    if input_data is None:
        if logger:
            logger.debug("input_data 為 None，返回空 dict")
        return {}

    if not isinstance(input_data, dict):
        if logger:
            logger.warning("input_data 非 dict 類型，返回空 dict: {}".format(type(input_data)))
        return {}

    tool_input = input_data.get("tool_input")

    # tool_input 為 None 或不存在時返回 {}
    if tool_input is None:
        if logger:
            logger.debug("tool_input 欄位為 None 或不存在，返回空 dict")
        return {}

    # tool_input 應為 dict，但可能是其他型別
    if not isinstance(tool_input, dict):
        if logger:
            logger.warning("tool_input 非 dict 類型，返回空 dict: {}".format(type(tool_input)))
        return {}

    if logger:
        logger.debug("成功提取 tool_input，欄位數: {}".format(len(tool_input)))

    return tool_input


def extract_tool_response(
    input_data: "dict | None",
    logger: "logging.Logger | None" = None
) -> dict:
    """安全提取 input_data 中的 tool_response 欄位

    處理三種情況：
    1. input_data 為 None 或空值 → 返回 {}
    2. tool_response 欄位缺失或為 None → 返回 {}
    3. tool_response 為有效的 dict → 返回該 dict

    Args:
        input_data: Hook 輸入資料（dict 或 None）
        logger: 可選 Logger 實例，用於記錄詳細資訊

    Returns:
        dict: 提取出的 tool_response（始終返回 dict，無欄位時返回空 dict）

    Examples:
        >>> extract_tool_response({"tool_response": {"stdout": "OK", "exit_code": 0}})
        {'stdout': 'OK', 'exit_code': 0}

        >>> extract_tool_response({"other": "value"})
        {}

        >>> extract_tool_response(None)
        {}
    """
    if input_data is None:
        if logger:
            logger.debug("input_data 為 None，返回空 dict")
        return {}

    if not isinstance(input_data, dict):
        if logger:
            logger.warning("input_data 非 dict 類型，返回空 dict: {}".format(type(input_data)))
        return {}

    tool_response = input_data.get("tool_response")

    # tool_response 為 None 或不存在時返回 {}
    if tool_response is None:
        if logger:
            logger.debug("tool_response 欄位為 None 或不存在，返回空 dict")
        return {}

    # tool_response 應為 dict，但可能是其他型別
    if not isinstance(tool_response, dict):
        if logger:
            logger.warning("tool_response 非 dict 類型，返回空 dict: {}".format(type(tool_response)))
        return {}

    if logger:
        logger.debug("成功提取 tool_response，欄位數: {}".format(len(tool_response)))

    return tool_response
