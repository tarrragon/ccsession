import 'package:ccsession/features/conversation/presentation/conversation_search_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：搜尋列 Widget（Phase 1 5.1）
/// 約束：包含 TextField、匹配計數、上/下導航按鈕、關閉按鈕
/// 維護：Enter=nextMatch, Shift+Enter=previousMatch, Escape=closeSearch
class ConversationSearchBar extends ConsumerStatefulWidget {
  const ConversationSearchBar({super.key});

  @override
  ConsumerState<ConversationSearchBar> createState() =>
      _ConversationSearchBarState();
}

class _ConversationSearchBarState
    extends ConsumerState<ConversationSearchBar> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(conversationSearchNotifierProvider);

    if (!searchState.isSearchVisible) {
      return const SizedBox.shrink();
    }

    // 需求：搜尋列開啟時自動聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return _buildSearchRow(searchState);
  }

  Widget _buildSearchRow(ConversationSearchState searchState) {
    final hasMatches = searchState.hasMatches;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _buildTextField()),
          if (searchState.matchCountDisplay.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(searchState.matchCountDisplay),
            ),
          _buildNavigationButton(
            icon: Icons.keyboard_arrow_up,
            onPressed: hasMatches ? _onPreviousMatch : null,
          ),
          _buildNavigationButton(
            icon: Icons.keyboard_arrow_down,
            onPressed: hasMatches ? _onNextMatch : null,
          ),
          _buildNavigationButton(
            icon: Icons.close,
            onPressed: _onCloseSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: const InputDecoration(
          hintText: 'Search...',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        onChanged: _onQueryChanged,
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 20,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _onCloseSearch();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _onPreviousMatch();
      } else {
        _onNextMatch();
      }
    }
  }

  void _onQueryChanged(String query) {
    ref.read(conversationSearchNotifierProvider.notifier).updateQuery(query);
  }

  void _onNextMatch() {
    ref.read(conversationSearchNotifierProvider.notifier).nextMatch();
  }

  void _onPreviousMatch() {
    ref.read(conversationSearchNotifierProvider.notifier).previousMatch();
  }

  void _onCloseSearch() {
    _controller.clear();
    ref.read(conversationSearchNotifierProvider.notifier).closeSearch();
  }
}
