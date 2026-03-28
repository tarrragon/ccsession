import 'package:ccsession/core/constants/conversation_constants.dart';
import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/assistant_message_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/empty_content_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:ccsession/features/conversation/presentation/widgets/thinking_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_result_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_use_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/user_message_bubble.dart';
import 'package:flutter/material.dart';

/// 需求：根據 SessionEvent.type 選擇對應的 Bubble Widget（Phase 3a 4.2）
/// 約束：空內容顯示 fallback 提示文字，未知類型回傳 SizedBox.shrink
/// 維護：highlightRanges 為 optional，搜尋功能注入高亮範圍（0.2.0-W2-005.2）
/// 維護：[0.2.1-W4-003] 空內容改為顯示 fallback 提示，不再隱藏
abstract final class MessageBubbleFactory {
  /// 需求：建構對應類型的 Bubble Widget
  /// 約束：各類型空內容顯示 EmptyContentBubble，highlightRanges 傳入各 Bubble
  static Widget build(
    SessionEvent event, {
    List<HighlightRange>? highlightRanges,
  }) {
    return switch (event.type) {
      'user' => _buildUserOrFallback(event, highlightRanges),
      'assistant' => _buildAssistantOrFallback(event, highlightRanges),
      'tool_use' => _buildToolUseOrFallback(event, highlightRanges),
      'tool_result' => ToolResultBubble(
          event: event, highlightRanges: highlightRanges),
      'thinking' => _buildThinkingOrFallback(event, highlightRanges),
      _ => const SizedBox.shrink(),
    };
  }

  /// 需求：[0.2.1-W4-003] 空文字 user 事件顯示 fallback
  static Widget _buildUserOrFallback(
    SessionEvent event,
    List<HighlightRange>? highlightRanges,
  ) {
    if (event.content.text.trim().isEmpty) {
      return const EmptyContentBubble(
        eventType: 'user',
        alignment: Alignment.centerRight,
      );
    }
    return UserMessageBubble(
        event: event, highlightRanges: highlightRanges);
  }

  /// 需求：[0.2.1-W4-003] 空文字 assistant 事件顯示 fallback
  static Widget _buildAssistantOrFallback(
    SessionEvent event,
    List<HighlightRange>? highlightRanges,
  ) {
    if (event.content.text.trim().isEmpty) {
      return const EmptyContentBubble(
        eventType: 'assistant',
        alignment: Alignment.centerLeft,
      );
    }
    return AssistantMessageBubble(
        event: event, highlightRanges: highlightRanges);
  }

  /// 需求：[0.2.1-W4-003] 空 toolName 的 tool_use 事件顯示 fallback
  static Widget _buildToolUseOrFallback(
    SessionEvent event,
    List<HighlightRange>? highlightRanges,
  ) {
    if (event.content.toolName.trim().isEmpty) {
      return const EmptyContentBubble(eventType: 'tool_use');
    }
    return ToolUseBubble(event: event, highlightRanges: highlightRanges);
  }

  /// 需求：[0.2.1-W4-003] 空文字 thinking 事件顯示 fallback
  static Widget _buildThinkingOrFallback(
    SessionEvent event,
    List<HighlightRange>? highlightRanges,
  ) {
    if (event.content.text.trim().isEmpty) {
      return const EmptyContentBubble(eventType: 'thinking');
    }
    return ThinkingBubble(event: event, highlightRanges: highlightRanges);
  }
}
