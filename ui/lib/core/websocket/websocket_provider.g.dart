// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$webSocketServiceHash() => r'64ffd33123c2019df2f64fc3d4c170b908be39f4';

/// 需求：WebSocketService 單例 provider
/// 約束：ref.onDispose 時釋放資源
///
/// Copied from [webSocketService].
@ProviderFor(webSocketService)
final webSocketServiceProvider = AutoDisposeProvider<WebSocketService>.internal(
  webSocketService,
  name: r'webSocketServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$webSocketServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WebSocketServiceRef = AutoDisposeProviderRef<WebSocketService>;
String _$connectionStateHash() => r'448ffe84aaec2cb30733b5d8783bc97fa5721839';

/// 需求：連線狀態（reactive stream）
///
/// Copied from [connectionState].
@ProviderFor(connectionState)
final connectionStateProvider =
    AutoDisposeStreamProvider<WsConnectionState>.internal(
      connectionState,
      name: r'connectionStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectionStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectionStateRef = AutoDisposeStreamProviderRef<WsConnectionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
