import 'package:flutter/material.dart';

/// 需求：UC-004 可拖拉的分隔線，調整相鄰面板大小
/// 約束：Phase 1 面板比例由 Widget 本地 State 管理，不持久化
class ResizableDivider extends StatefulWidget {
  const ResizableDivider({
    required this.axis,
    required this.onDrag,
    super.key,
  });

  /// 分隔線方向
  final Axis axis;

  /// 拖拉時的 callback，傳入 delta 值（像素）
  final ValueChanged<double> onDrag;

  /// 分隔線粗細（像素）
  static const double thickness = 8;

  @override
  State<ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends State<ResizableDivider> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.axis == Axis.horizontal;
    final cursor = isHorizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;

    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onHorizontalDragUpdate: isHorizontal
            ? (details) => widget.onDrag(details.delta.dx)
            : null,
        onVerticalDragUpdate: !isHorizontal
            ? (details) => widget.onDrag(details.delta.dy)
            : null,
        child: Container(
          width: isHorizontal ? ResizableDivider.thickness : double.infinity,
          height: !isHorizontal ? ResizableDivider.thickness : double.infinity,
          color: _isHovering
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}
