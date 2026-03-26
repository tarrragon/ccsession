import 'package:ccsession/core/constants/session_list_constants.dart';
import 'package:ccsession/core/models/session_info.dart';
import 'package:flutter/material.dart';

/// 需求：圓形狀態指示燈
/// 規格：active=綠色, idle=琥珀色, completed=灰色
/// 約束：顏色映射來自 SessionListConstants.statusColor
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
  });

  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SessionListConstants.statusIndicatorSize,
      height: SessionListConstants.statusIndicatorSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SessionListConstants.statusColor(status),
      ),
    );
  }
}
