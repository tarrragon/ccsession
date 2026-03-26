import 'package:ccsession/core/models/connection_state.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/features/dashboard/presentation/dashboard_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 需求：WebSocket 連線狀態指示器，顯示於 sidebar 頂部
/// 約束：ConsumerWidget，watch connectionStateProvider
/// 視覺：彩色圓點（綠/黃/紅）+ 文字狀態描述
class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStateAsync = ref.watch(connectionStateProvider);
    final wsState = connectionStateAsync.valueOrNull ??
        WsConnectionState.connecting;
    return _buildBar(wsState);
  }

  /// 建構 ConnectionStatusBar UI
  Widget _buildBar(WsConnectionState state) {
    return Container(
      padding: DashboardConstants.connectionBarPadding,
      child: Row(
        children: [
          Container(
            width: DashboardConstants.connectionDotSize,
            height: DashboardConstants.connectionDotSize,
            decoration: BoxDecoration(
              color: _colorForState(state),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DashboardConstants.connectionDotTextSpacing),
          Text(_textForState(state)),
        ],
      ),
    );
  }

  /// 連線狀態 -> 圓點顏色映射
  Color _colorForState(WsConnectionState state) {
    return switch (state) {
      WsConnectionState.connected => Colors.green,
      WsConnectionState.connecting => Colors.amber,
      WsConnectionState.reconnecting => Colors.amber,
      WsConnectionState.disconnected => Colors.red,
    };
  }

  /// 連線狀態 -> 文字描述映射
  String _textForState(WsConnectionState state) {
    return switch (state) {
      WsConnectionState.connected => 'Connected',
      WsConnectionState.connecting => 'Connecting...',
      WsConnectionState.reconnecting => 'Reconnecting...',
      WsConnectionState.disconnected => 'Disconnected',
    };
  }
}
