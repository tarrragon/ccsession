// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_group_ui_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionGroupUiNotifierHash() =>
    r'e510df991366494285286b03a82dc8184c5b1abf';

/// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
/// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
///
/// Copied from [SessionGroupUiNotifier].
@ProviderFor(SessionGroupUiNotifier)
final sessionGroupUiNotifierProvider =
    AutoDisposeNotifierProvider<
      SessionGroupUiNotifier,
      SessionGroupUiState
    >.internal(
      SessionGroupUiNotifier.new,
      name: r'sessionGroupUiNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionGroupUiNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionGroupUiNotifier = AutoDisposeNotifier<SessionGroupUiState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
