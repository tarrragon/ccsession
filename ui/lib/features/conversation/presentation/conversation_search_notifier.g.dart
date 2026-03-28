// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationSearchNotifierHash() =>
    r'2e2c74ecbb61a30b4e5e9c06144a72cd1ec00554';

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

abstract class _$ConversationSearchNotifier
    extends BuildlessAutoDisposeNotifier<ConversationSearchState> {
  late final int panelIndex;

  ConversationSearchState build(int panelIndex);
}

/// 需求：管理對話搜尋狀態（Phase 1 4.1）
/// 約束：監聽 conversationNotifierProvider，events 變化時自動重新搜尋
/// 維護：debounce 使用簡單 Timer，不引入 RxDart
/// 維護：_currentSearch 用於跨 build() 重建保留搜尋狀態
///
/// Copied from [ConversationSearchNotifier].
@ProviderFor(ConversationSearchNotifier)
const conversationSearchNotifierProvider = ConversationSearchNotifierFamily();

/// 需求：管理對話搜尋狀態（Phase 1 4.1）
/// 約束：監聽 conversationNotifierProvider，events 變化時自動重新搜尋
/// 維護：debounce 使用簡單 Timer，不引入 RxDart
/// 維護：_currentSearch 用於跨 build() 重建保留搜尋狀態
///
/// Copied from [ConversationSearchNotifier].
class ConversationSearchNotifierFamily extends Family<ConversationSearchState> {
  /// 需求：管理對話搜尋狀態（Phase 1 4.1）
  /// 約束：監聽 conversationNotifierProvider，events 變化時自動重新搜尋
  /// 維護：debounce 使用簡單 Timer，不引入 RxDart
  /// 維護：_currentSearch 用於跨 build() 重建保留搜尋狀態
  ///
  /// Copied from [ConversationSearchNotifier].
  const ConversationSearchNotifierFamily();

  /// 需求：管理對話搜尋狀態（Phase 1 4.1）
  /// 約束：監聽 conversationNotifierProvider，events 變化時自動重新搜尋
  /// 維護：debounce 使用簡單 Timer，不引入 RxDart
  /// 維護：_currentSearch 用於跨 build() 重建保留搜尋狀態
  ///
  /// Copied from [ConversationSearchNotifier].
  ConversationSearchNotifierProvider call(int panelIndex) {
    return ConversationSearchNotifierProvider(panelIndex);
  }

  @override
  ConversationSearchNotifierProvider getProviderOverride(
    covariant ConversationSearchNotifierProvider provider,
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
  String? get name => r'conversationSearchNotifierProvider';
}

/// 需求：管理對話搜尋狀態（Phase 1 4.1）
/// 約束：監聽 conversationNotifierProvider，events 變化時自動重新搜尋
/// 維護：debounce 使用簡單 Timer，不引入 RxDart
/// 維護：_currentSearch 用於跨 build() 重建保留搜尋狀態
///
/// Copied from [ConversationSearchNotifier].
class ConversationSearchNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          ConversationSearchNotifier,
          ConversationSearchState
        > {
  /// 需求：管理對話搜尋狀態（Phase 1 4.1）
  /// 約束：監聽 conversationNotifierProvider，events 變化時自動重新搜尋
  /// 維護：debounce 使用簡單 Timer，不引入 RxDart
  /// 維護：_currentSearch 用於跨 build() 重建保留搜尋狀態
  ///
  /// Copied from [ConversationSearchNotifier].
  ConversationSearchNotifierProvider(int panelIndex)
    : this._internal(
        () => ConversationSearchNotifier()..panelIndex = panelIndex,
        from: conversationSearchNotifierProvider,
        name: r'conversationSearchNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationSearchNotifierHash,
        dependencies: ConversationSearchNotifierFamily._dependencies,
        allTransitiveDependencies:
            ConversationSearchNotifierFamily._allTransitiveDependencies,
        panelIndex: panelIndex,
      );

  ConversationSearchNotifierProvider._internal(
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
  ConversationSearchState runNotifierBuild(
    covariant ConversationSearchNotifier notifier,
  ) {
    return notifier.build(panelIndex);
  }

  @override
  Override overrideWith(ConversationSearchNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ConversationSearchNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<
    ConversationSearchNotifier,
    ConversationSearchState
  >
  createElement() {
    return _ConversationSearchNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationSearchNotifierProvider &&
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
mixin ConversationSearchNotifierRef
    on AutoDisposeNotifierProviderRef<ConversationSearchState> {
  /// The parameter `panelIndex` of this provider.
  int get panelIndex;
}

class _ConversationSearchNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          ConversationSearchNotifier,
          ConversationSearchState
        >
    with ConversationSearchNotifierRef {
  _ConversationSearchNotifierProviderElement(super.provider);

  @override
  int get panelIndex =>
      (origin as ConversationSearchNotifierProvider).panelIndex;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
