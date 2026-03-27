import 'package:ccsession/features/session_list/presentation/project_tab_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TG-32: ProjectTabNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // TC-32-01: 初始狀態
    test('initial value is 0', () {
      final index = container.read(projectTabNotifierProvider);

      expect(index, 0);
    });

    // TC-32-02: 正常 — 選擇 Tab
    test('selectTab updates index', () {
      expect(container.read(projectTabNotifierProvider), 0);

      container
          .read(projectTabNotifierProvider.notifier)
          .selectTab(2);

      expect(container.read(projectTabNotifierProvider), 2);
    });

    // TC-32-03: 正常 — 多次切換
    test('multiple selectTab calls result in last value', () {
      final notifier =
          container.read(projectTabNotifierProvider.notifier);

      notifier.selectTab(1);
      notifier.selectTab(3);
      notifier.selectTab(0);

      expect(container.read(projectTabNotifierProvider), 0);
    });
  });
}
