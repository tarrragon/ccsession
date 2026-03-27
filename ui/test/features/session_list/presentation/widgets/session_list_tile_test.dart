import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/widgets/session_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_session_factory.dart';

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
    testWidgets('displays summary and agentName', (tester) async {
      final session = createTestSession(
        summary: 'Fix bug',
        projectPath: '/p/myapp',
        agentName: 'main',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('Fix bug'), findsOneWidget);
      expect(find.text('main'), findsOneWidget);
    });

    // TC-14-02: 摘要為空時使用 lastMessage fallback
    testWidgets('uses lastMessage fallback when summary is empty',
        (tester) async {
      final longMessage =
          'A very long message that exceeds fifty characters limit here and more';
      final session = createTestSession(
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
      final session = createTestSession(
        id: 'abcdef01-2345-6789-abcd-ef0123456789',
        summary: '',
        lastMessage: '',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('abcdef01'), findsOneWidget);
    });

    // TC-14-04: 選中狀態視覺區分
    testWidgets('selected tile has different visual style', (tester) async {
      final session = createTestSession();
      await tester.pumpWidget(buildSubject(session, isSelected: true));

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.selected, isTrue);
    });
  });

  group('TG-14B: Agent 前綴標題', () {
    Widget buildSubject(SessionInfo session) {
      return MaterialApp(
        home: Scaffold(
          body: SessionListTile(session: session, isSelected: false),
        ),
      );
    }

    // B-1: agentType 非空 + summary 非空 -> "[Agent] {summary}"
    testWidgets('agent session title has [Agent] prefix', (tester) async {
      final session = createTestSession(
        agentType: 'parsley',
        summary: '執行測試',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.textContaining('[Agent]'), findsOneWidget);
      expect(find.text('[Agent] 執行測試'), findsOneWidget);
    });

    // B-2: agentType 空 + summary 非空 -> 無前綴
    testWidgets('non-agent session title has no prefix', (tester) async {
      final session = createTestSession(
        agentType: '',
        summary: '修改設定',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('修改設定'), findsOneWidget);
      expect(find.textContaining('[Agent]'), findsNothing);
    });

    // B-3: agentType 非空 + summary 空 + lastMessage 非空
    testWidgets('agent session falls back to lastMessage with prefix',
        (tester) async {
      final session = createTestSession(
        agentType: 'sage',
        summary: '',
        lastMessage: '任務完成報告已提交',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('[Agent] 任務完成報告已提交'), findsOneWidget);
    });

    // B-4: agentType 非空 + 全空 -> "[Agent] {id 前 8 字}"
    testWidgets('agent session falls back to id prefix with [Agent]',
        (tester) async {
      final session = createTestSession(
        id: 'abc12345-xxxx-yyyy',
        agentType: 'rosemary',
        summary: '',
        lastMessage: '',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('[Agent] abc12345'), findsOneWidget);
    });
  });

  group('TG-14C: 副標題移除 projectName', () {
    Widget buildSubject(SessionInfo session) {
      return MaterialApp(
        home: Scaffold(
          body: SessionListTile(session: session, isSelected: false),
        ),
      );
    }

    // C-1: projectPath 非空但副標題不含專案名
    testWidgets('subtitle does not contain project name', (tester) async {
      final session = createTestSession(
        projectPath: '/path/to/myapp',
        agentName: '',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.textContaining('myapp'), findsNothing);
    });

    // C-2: agentName 非空 -> 副標題只有 agentName
    testWidgets('subtitle shows only agentName', (tester) async {
      final session = createTestSession(
        projectPath: '/path/to/myapp',
        agentName: 'rosemary',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('rosemary'), findsOneWidget);
      expect(find.textContaining('myapp'), findsNothing);
    });

    // C-3: 全空 -> 副標題空字串
    testWidgets('subtitle is empty when agentName is empty', (tester) async {
      final session = createTestSession(
        projectPath: '',
        agentName: '',
      );
      await tester.pumpWidget(buildSubject(session));

      // subtitle Text widget exists but with empty string
      final subtitleFinder = find.byWidgetPredicate(
        (w) => w is Text && w.data == '',
      );
      expect(subtitleFinder, findsOneWidget);
    });
  });

  group('TG-14D: Fallback 邊界條件', () {
    Widget buildSubject(SessionInfo session) {
      return MaterialApp(
        home: Scaffold(
          body: SessionListTile(session: session, isSelected: false),
        ),
      );
    }

    // D-2: lastMessage 恰好 50 字不截斷
    testWidgets('lastMessage exactly 50 chars is not truncated',
        (tester) async {
      final message = 'A' * 50;
      final session = createTestSession(
        summary: '',
        lastMessage: message,
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text(message), findsOneWidget);
    });

    // D-3: ID 長度 < 8 不越界
    testWidgets('short id does not cause out of bounds', (tester) async {
      final session = createTestSession(
        id: 'abc',
        summary: '',
        lastMessage: '',
      );
      await tester.pumpWidget(buildSubject(session));

      expect(find.text('abc'), findsOneWidget);
    });
  });
}
