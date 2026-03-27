// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_view_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$splitViewNotifierHash() => r'f7d85f4bfa34a7046af9e2110d524960ffb891c5';

/// 需求：UC-004 管理分割畫面狀態
/// 約束：@riverpod code generation，從 SplitViewStorage 讀取/寫入持久化狀態
///
/// Copied from [SplitViewNotifier].
@ProviderFor(SplitViewNotifier)
final splitViewNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      SplitViewNotifier,
      SplitViewState
    >.internal(
      SplitViewNotifier.new,
      name: r'splitViewNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$splitViewNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SplitViewNotifier = AutoDisposeAsyncNotifier<SplitViewState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
