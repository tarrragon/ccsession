import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/presentation/split_view_notifier.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';
import 'package:ccsession/features/split_view/presentation/widgets/resizable_divider.dart';
import 'package:ccsession/features/split_view/presentation/widgets/session_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：UC-004 根據 layoutMode 切換面板佈局
/// 約束：ConsumerStatefulWidget，flex 比例為本地 State（不持久化）
class SplitViewContainer extends ConsumerStatefulWidget {
  const SplitViewContainer({super.key});

  @override
  ConsumerState<SplitViewContainer> createState() =>
      _SplitViewContainerState();
}

class _SplitViewContainerState extends ConsumerState<SplitViewContainer> {
  /// 需求：UC-004 面板 flex 比例，預設等分
  /// 約束：本地 State 管理，不持久化
  final Map<String, double> _flexValues = {};

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(splitViewNotifierProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: _buildLayout,
    );
  }

  Widget _buildLayout(SplitViewState state) {
    if (state.maximizedPanelIndex != null) {
      return SessionPanel(panelIndex: state.maximizedPanelIndex!);
    }

    switch (state.layoutMode) {
      case LayoutMode.single:
        return const SessionPanel(panelIndex: 0);
      case LayoutMode.splitHorizontal:
        return _buildSplitLayout(axis: Axis.horizontal);
      case LayoutMode.splitVertical:
        return _buildSplitLayout(axis: Axis.vertical);
      case LayoutMode.grid2x2:
        return _buildGrid2x2();
    }
  }

  /// 需求：UC-004 水平/垂直雙面板佈局
  /// 約束：axis 決定 Row(horizontal) 或 Column(vertical)
  Widget _buildSplitLayout({required Axis axis}) {
    final isHorizontal = axis == Axis.horizontal;
    final firstKey = isHorizontal ? 'h-left' : 'v-top';
    final secondKey = isHorizontal ? 'h-right' : 'v-bottom';
    final firstFlex = _getFlex(firstKey);
    final secondFlex = _getFlex(secondKey);

    final children = [
      Expanded(flex: firstFlex, child: const SessionPanel(panelIndex: 0)),
      ResizableDivider(
        axis: axis,
        onDrag: (delta) => _handleDrag(firstKey, secondKey, delta),
      ),
      Expanded(flex: secondFlex, child: const SessionPanel(panelIndex: 1)),
    ];

    return isHorizontal ? Row(children: children) : Column(children: children);
  }

  Widget _buildGrid2x2() {
    final topFlex = _getFlex('g-top');
    final bottomFlex = _getFlex('g-bottom');
    return Column(
      children: [
        Expanded(
          flex: topFlex,
          child: _buildGridRow(
            leftKey: 'g-top-left',
            rightKey: 'g-top-right',
            leftPanelIndex: 0,
            rightPanelIndex: 1,
          ),
        ),
        ResizableDivider(
          axis: Axis.vertical,
          onDrag: (delta) => _handleDrag('g-top', 'g-bottom', delta),
        ),
        Expanded(
          flex: bottomFlex,
          child: _buildGridRow(
            leftKey: 'g-bottom-left',
            rightKey: 'g-bottom-right',
            leftPanelIndex: 2,
            rightPanelIndex: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildGridRow({
    required String leftKey,
    required String rightKey,
    required int leftPanelIndex,
    required int rightPanelIndex,
  }) {
    return Row(
      children: [
        Expanded(
          flex: _getFlex(leftKey),
          child: SessionPanel(panelIndex: leftPanelIndex),
        ),
        ResizableDivider(
          axis: Axis.horizontal,
          onDrag: (delta) => _handleDrag(leftKey, rightKey, delta),
        ),
        Expanded(
          flex: _getFlex(rightKey),
          child: SessionPanel(panelIndex: rightPanelIndex),
        ),
      ],
    );
  }

  int _getFlex(String key) => (_flexValues[key] ?? 100).round();

  void _handleDrag(String leftKey, String rightKey, double delta) {
    setState(() {
      final leftFlex = _flexValues[leftKey] ?? 100.0;
      final rightFlex = _flexValues[rightKey] ?? 100.0;
      _flexValues[leftKey] = (leftFlex + delta).clamp(20, 280);
      _flexValues[rightKey] = (rightFlex - delta).clamp(20, 280);
    });
  }
}
