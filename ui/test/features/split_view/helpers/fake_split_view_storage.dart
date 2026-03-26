import 'package:ccsession/features/split_view/data/split_view_storage.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';

/// 需求：UC-004 測試替身，記憶體實作 SplitViewStorage
class FakeSplitViewStorage implements SplitViewStorage {
  SplitViewState? savedState;
  SplitViewState? loadResult;
  int saveCallCount = 0;
  bool shouldThrow = false;

  @override
  Future<void> save(SplitViewState state) async {
    if (shouldThrow) throw Exception('FakeSplitViewStorage save error');
    savedState = state;
    saveCallCount++;
  }

  @override
  Future<SplitViewState?> load() async {
    if (shouldThrow) throw Exception('FakeSplitViewStorage load error');
    return loadResult ?? savedState;
  }

  @override
  Future<void> clear() async {
    savedState = null;
  }
}
