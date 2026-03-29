// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedSessionIdHash() => r'76f7a7311260e75dedf2154814c89837e50fc0e4';

/// 需求：暴露當前選中的 session ID 供其他模組消費
///
/// Copied from [selectedSessionId].
@ProviderFor(selectedSessionId)
final selectedSessionIdProvider = AutoDisposeProvider<String?>.internal(
  selectedSessionId,
  name: r'selectedSessionIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedSessionIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelectedSessionIdRef = AutoDisposeProviderRef<String?>;
String _$sessionListNotifierHash() =>
    r'af443af8dce03e5a52c9d6fa6d948ee7ca2f5edd';

/// 需求：管理 session 列表狀態，消費 WebSocket 訊息
/// 約束：使用 @riverpod code generation
///
/// Copied from [SessionListNotifier].
@ProviderFor(SessionListNotifier)
final sessionListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      SessionListNotifier,
      SessionListState
    >.internal(
      SessionListNotifier.new,
      name: r'sessionListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionListNotifier = AutoDisposeAsyncNotifier<SessionListState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
