import 'dart:math';

import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_group_ui_state.dart';
import 'package:flutter/foundation.dart';

/// 需求：[0.2.1-W2-002] ListView 項目的 sealed class 階層
/// 約束：sealed class + pattern matching，消除 nullable 欄位
sealed class SessionListItem {}

/// 需求：分組標題項目
final class HeaderItem extends SessionListItem {
  HeaderItem({
    required this.status,
    required this.count,
    required this.isExpanded,
  });
  final SessionStatus status;
  final int count;
  final bool isExpanded;
}

/// 需求：Session 磁磚項目
final class TileItem extends SessionListItem {
  TileItem({required this.session});
  final SessionInfo session;
}

/// 需求：分頁控制項目
final class PaginationItem extends SessionListItem {
  PaginationItem({
    required this.status,
    required this.currentPage,
    required this.totalPages,
  });
  final SessionStatus status;
  final int currentPage;
  final int totalPages;
}

/// 需求：[0.2.1-W2-002] 展平分組 Map 為 ListView 可消費的線性列表
/// 約束：根據 uiState 決定摺疊和分頁裁切
/// 維護：pageSize 來自 SessionListConstants.maxItemsPerPage
@visibleForTesting
List<SessionListItem> flattenGroups(
  Map<SessionStatus, List<SessionInfo>> grouped,
  SessionGroupUiState uiState,
) {
  final items = <SessionListItem>[];
  for (final entry in grouped.entries) {
    items.addAll(_buildGroupItems(entry.key, entry.value, uiState));
  }
  return items;
}

/// 需求：展平單一分組為 Header + Tiles + Pagination 項目
/// 約束：摺疊時只回傳 Header；展開時回傳分頁裁切後的 Tiles
List<SessionListItem> _buildGroupItems(
  SessionStatus status,
  List<SessionInfo> sessions,
  SessionGroupUiState uiState,
) {
  final items = <SessionListItem>[];
  final count = sessions.length;
  final isExpanded = uiState.expandedGroups[status] ?? true;
  items.add(HeaderItem(status: status, count: count, isExpanded: isExpanded));

  if (!isExpanded) return items;

  final pageSize = SessionListConstants.maxItemsPerPage;
  final totalPages = (count / pageSize).ceil();
  final rawPage = uiState.currentPages[status] ?? 0;
  final safePage = rawPage.clamp(0, max(totalPages - 1, 0)).toInt();

  final paginated = _paginateSessions(sessions, safePage, pageSize);
  for (final session in paginated) {
    items.add(TileItem(session: session));
  }

  if (totalPages > 1) {
    items.add(PaginationItem(
      status: status,
      currentPage: safePage,
      totalPages: totalPages,
    ));
  }

  return items;
}

/// 需求：從 sessions 列表中裁切出指定頁的子列表
/// 約束：純函式，不修改原列表
List<SessionInfo> _paginateSessions(
  List<SessionInfo> sessions,
  int page,
  int pageSize,
) {
  final startIndex = page * pageSize;
  final endIndex = min(startIndex + pageSize, sessions.length);
  return sessions.sublist(startIndex, endIndex);
}
