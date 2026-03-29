// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationNotifierHash() =>
    r'6719e1e6e7134d2bcc1e22d54adc9cb8de587565';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ConversationNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ConversationState> {
  late final int panelIndex;

  FutureOr<ConversationState> build(int panelIndex);
}

/// 需求：管理 session 對話狀態，消費 WebSocket 訊息
/// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
///
/// Copied from [ConversationNotifier].
@ProviderFor(ConversationNotifier)
const conversationNotifierProvider = ConversationNotifierFamily();

/// 需求：管理 session 對話狀態，消費 WebSocket 訊息
/// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
///
/// Copied from [ConversationNotifier].
class ConversationNotifierFamily extends Family<AsyncValue<ConversationState>> {
  /// 需求：管理 session 對話狀態，消費 WebSocket 訊息
  /// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
  ///
  /// Copied from [ConversationNotifier].
  const ConversationNotifierFamily();

  /// 需求：管理 session 對話狀態，消費 WebSocket 訊息
  /// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
  ///
  /// Copied from [ConversationNotifier].
  ConversationNotifierProvider call(int panelIndex) {
    return ConversationNotifierProvider(panelIndex);
  }

  @override
  ConversationNotifierProvider getProviderOverride(
    covariant ConversationNotifierProvider provider,
  ) {
    return call(provider.panelIndex);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationNotifierProvider';
}

/// 需求：管理 session 對話狀態，消費 WebSocket 訊息
/// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
///
/// Copied from [ConversationNotifier].
class ConversationNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ConversationNotifier,
          ConversationState
        > {
  /// 需求：管理 session 對話狀態，消費 WebSocket 訊息
  /// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
  ///
  /// Copied from [ConversationNotifier].
  ConversationNotifierProvider(int panelIndex)
    : this._internal(
        () => ConversationNotifier()..panelIndex = panelIndex,
        from: conversationNotifierProvider,
        name: r'conversationNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationNotifierHash,
        dependencies: ConversationNotifierFamily._dependencies,
        allTransitiveDependencies:
            ConversationNotifierFamily._allTransitiveDependencies,
        panelIndex: panelIndex,
      );

  ConversationNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.panelIndex,
  }) : super.internal();

  final int panelIndex;

  @override
  FutureOr<ConversationState> runNotifierBuild(
    covariant ConversationNotifier notifier,
  ) {
    return notifier.build(panelIndex);
  }

  @override
  Override overrideWith(ConversationNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ConversationNotifierProvider._internal(
        () => create()..panelIndex = panelIndex,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        panelIndex: panelIndex,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ConversationNotifier,
    ConversationState
  >
  createElement() {
    return _ConversationNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationNotifierProvider &&
        other.panelIndex == panelIndex;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, panelIndex.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ConversationState> {
  /// The parameter `panelIndex` of this provider.
  int get panelIndex;
}

class _ConversationNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ConversationNotifier,
          ConversationState
        >
    with ConversationNotifierRef {
  _ConversationNotifierProviderElement(super.provider);

  @override
  int get panelIndex => (origin as ConversationNotifierProvider).panelIndex;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
