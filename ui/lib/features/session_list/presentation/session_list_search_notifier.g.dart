// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_list_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionListSearchNotifierHash() =>
    r'544bafbd5cabd2c5221e6074fd071650b3af8d4f';

/// 需求：[0.2.0-W4-003] 管理 session 列表篩選狀態
/// 約束：監聽 sessionListNotifierProvider，sessions 變化時自動重新篩選
/// 維護：debounce 延遲 state 更新，TextField 由 controller 管理輸入顯示
/// 維護：_currentSearch 用於跨 build() 重建保留篩選狀態
///
/// Copied from [SessionListSearchNotifier].
@ProviderFor(SessionListSearchNotifier)
final sessionListSearchNotifierProvider =
    AutoDisposeNotifierProvider<
      SessionListSearchNotifier,
      SessionListSearchState
    >.internal(
      SessionListSearchNotifier.new,
      name: r'sessionListSearchNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionListSearchNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionListSearchNotifier =
    AutoDisposeNotifier<SessionListSearchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
