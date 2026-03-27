import 'package:flutter/material.dart';

/// 需求：[0.2.1-W2-002] 分頁控制 Widget
/// 約束：顯示「< 頁碼 / 總頁數 >」，首頁禁用上一頁、末頁禁用下一頁
class PaginationControls extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final void Function(int page) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final displayPage = currentPage + 1;
    final hasPrev = currentPage > 0;
    final hasNext = currentPage < totalPages - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: hasPrev ? () => onPageChanged(currentPage - 1) : null,
        ),
        Text('$displayPage / $totalPages'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: hasNext ? () => onPageChanged(currentPage + 1) : null,
        ),
      ],
    );
  }
}
