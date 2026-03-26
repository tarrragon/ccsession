import 'package:ccsession/core/constants/search_constants.dart';
import 'package:ccsession/features/session_list/presentation/session_list_search_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：[0.2.0-W4-003] Session 列表搜尋列 Widget
/// 約束：包含 TextField 和關閉按鈕（無導航按鈕，與 ConversationSearchBar 不同）
/// 維護：Escape 鍵關閉搜尋列
class SessionListSearchBar extends ConsumerStatefulWidget {
  const SessionListSearchBar({super.key});

  @override
  ConsumerState<SessionListSearchBar> createState() =>
      _SessionListSearchBarState();
}

class _SessionListSearchBarState extends ConsumerState<SessionListSearchBar> {
  final _focusNode = FocusNode();
  final _keyboardListenerFocusNode = FocusNode();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(sessionListSearchNotifierProvider);

    if (!searchState.isSearchVisible) {
      return const SizedBox.shrink();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return _buildSearchRow();
  }

  Widget _buildSearchRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _buildTextField()),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return KeyboardListener(
      focusNode: _keyboardListenerFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: SearchConstants.sessionFilterHint,
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        onChanged: _onQueryChanged,
      ),
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: _onCloseSearch,
      iconSize: 20,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _onCloseSearch();
    }
  }

  void _onQueryChanged(String query) {
    ref
        .read(sessionListSearchNotifierProvider.notifier)
        .updateQuery(query);
  }

  void _onCloseSearch() {
    _controller.clear();
    ref.read(sessionListSearchNotifierProvider.notifier).closeSearch();
  }
}
