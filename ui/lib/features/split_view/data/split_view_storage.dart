import 'dart:convert';

import 'package:ccsession/features/split_view/domain/layout_mode.dart';
import 'package:ccsession/features/split_view/domain/panel_state.dart';
import 'package:ccsession/features/split_view/domain/split_view_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 需求：UC-004 分割畫面狀態持久化介面
/// 約束：只持久化 layoutMode 和 panels[].sessionId
abstract class SplitViewStorage {
  /// 儲存分割畫面狀態
  Future<void> save(SplitViewState state);

  /// 讀取分割畫面狀態，不存在或損壞時回傳 null
  Future<SplitViewState?> load();

  /// 清除持久化資料
  Future<void> clear();
}

/// 需求：UC-004 基於 SharedPreferences 的持久化實作
/// 約束：JSON 字串儲存，key 為 split_view_state
class SharedPrefsSplitViewStorage implements SplitViewStorage {
  SharedPrefsSplitViewStorage(this._prefs);

  final SharedPreferences _prefs;

  /// SharedPreferences 儲存 key
  static const storageKey = 'split_view_state';

  @override
  Future<void> save(SplitViewState state) async {
    final json = _stateToJson(state);
    await _prefs.setString(storageKey, jsonEncode(json));
  }

  @override
  Future<SplitViewState?> load() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _stateFromJson(map);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(storageKey);
  }

  Map<String, dynamic> _stateToJson(SplitViewState state) {
    return {
      'layoutMode': state.layoutMode.name,
      'panels': state.panels
          .map((p) => {
                'panelIndex': p.panelIndex,
                'sessionId': p.sessionId,
              })
          .toList(),
    };
  }

  SplitViewState _stateFromJson(Map<String, dynamic> map) {
    final layoutMode = LayoutMode.values.byName(map['layoutMode'] as String);
    final panelsList = (map['panels'] as List<dynamic>)
        .map((p) => PanelState(
              panelIndex: (p as Map<String, dynamic>)['panelIndex'] as int,
              sessionId: p['sessionId'] as String?,
            ))
        .toList();
    return SplitViewState(
      layoutMode: layoutMode,
      panels: panelsList,
    );
  }
}

/// 需求：UC-004 SplitViewStorage Provider
/// 約束：必須在 ProviderScope overrides 中提供實作
final splitViewStorageProvider = Provider<SplitViewStorage>((ref) {
  throw UnimplementedError(
    'splitViewStorageProvider must be overridden in ProviderScope',
  );
});
