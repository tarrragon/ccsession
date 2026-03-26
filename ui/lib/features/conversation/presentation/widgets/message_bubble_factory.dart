import 'package:ccsession/core/models/session_event.dart';
import 'package:ccsession/features/conversation/presentation/widgets/assistant_message_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/search_highlight_utils.dart';
import 'package:ccsession/features/conversation/presentation/widgets/thinking_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_result_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/tool_use_bubble.dart';
import 'package:ccsession/features/conversation/presentation/widgets/user_message_bubble.dart';
import 'package:flutter/material.dart';

/// 需求：根據 SessionEvent.type 選擇對應的 Bubble Widget（Phase 3a 4.2）
/// 約束：未知類型回傳 SizedBox.shrink，thinking 空文字回傳 SizedBox.shrink
/// 維護：highlightRanges 為 optional，搜尋功能注入高亮範圍（0.2.0-W2-005.2）
abstract final class MessageBubbleFactory {
  /// 需求：建構對應類型的 Bubble Widget
  /// 約束：thinking 空文字過濾在此層處理，highlightRanges 傳入各 Bubble
  static Widget build(
    SessionEvent event, {
    List<HighlightRange>? highlightRanges,
  }) {
    return switch (event.type) {
      'user' => UserMessageBubble(event: event, highlightRanges: highlightRanges),
      'assistant' => AssistantMessageBubble(event: event, highlightRanges: highlightRanges),
      'tool_use' => ToolUseBubble(event: event, highlightRanges: highlightRanges),
      'tool_result' => ToolResultBubble(event: event, highlightRanges: highlightRanges),
      'thinking' => _buildThinkingOrEmpty(event),
      _ => const SizedBox.shrink(),
    };
  }

  static Widget _buildThinkingOrEmpty(SessionEvent event) {
    if (event.content.text.isEmpty) {
      return const SizedBox.shrink();
    }
    return ThinkingBubble(event: event);
  }
}
