import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _baseTime = DateTime(2026, 3, 25, 10, 0);

SessionInfo _createTestSession({
  String id = 'session-1',
  String projectPath = '/Users/test/project',
  String summary = 'Test summary',
  SessionStatus status = SessionStatus.active,
  DateTime? lastEventAt,
  String lastMessage = '',
  String agentName = 'claude',
}) {
  return SessionInfo(
    id: id,
    projectPath: projectPath,
    summary: summary,
    status: status,
    firstEventAt: _baseTime,
    lastEventAt: lastEventAt ?? _baseTime,
    lastMessage: lastMessage,
    agentName: agentName,
  );
}

void main() {
  group('TG-14: SessionListTile', () {
    Widget buildSubject(SessionInfo session, {bool isSelected = false}) {
      return MaterialApp(
        home: Scaffold(
          body: SessionListTile(
            session: session,
            isSelected: isSelected,
          ),
        ),
      );
    }

    // TC-14-01: 顯示 session 基本欄位
    testWidgets('displays summary and project name', (tester) async {
      final session = _createTestSession(
        summary: 'Fix bug',
        projectPath: '/p/myapp',
        agentName: 'main',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('Fix bug'), findsOneWidget);
      expect(find.text('myapp / main'), findsOneWidget);
    });

    // TC-14-02: 摘要為空時使用 lastMessage fallback
    testWidgets('uses lastMessage fallback when summary is empty',
        (tester) async {
      final longMessage =
          'A very long message that exceeds fifty characters limit here and more';
      final session = _createTestSession(
        summary: '',
        lastMessage: longMessage,
      );
      await tester.pumpWidget(buildSubject(session));

      // 應顯示前 50 字元
      expect(find.text(longMessage.substring(0, 50)), findsOneWidget);
    });

    // TC-14-03: summary 和 lastMessage 都為空時顯示 id 前 8 字元
    testWidgets('uses id fallback when summary and lastMessage are empty',
        (tester) async {
      final session = _createTestSession(
        id: 'abcdef01-2345-6789-abcd-ef0123456789',
        summary: '',
        lastMessage: '',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('abcdef01'), findsOneWidget);
    });

    // TC-14-04: 選中狀態視覺區分
    testWidgets('selected tile has different visual style', (tester) async {
      final session = _createTestSession();
      await tester.pumpWidget(buildSubject(session, isSelected: true));

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.selected, isTrue);
    });
  });
}
