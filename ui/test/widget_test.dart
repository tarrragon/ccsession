import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/features/split_view/data/split_view_storage.dart';
import 'package:ccsession/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/dashboard/presentation/dashboard_test_helpers.dart';
import 'features/split_view/helpers/fake_split_view_storage.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webSocketServiceProvider
              .overrideWithValue(FakeWebSocketService()),
          connectionStateProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          splitViewStorageProvider.overrideWithValue(FakeSplitViewStorage()),
        ],
        child: const App(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
