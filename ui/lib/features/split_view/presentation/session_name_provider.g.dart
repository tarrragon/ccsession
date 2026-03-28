// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_name_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionNameHash() => r'70daeddb1a87287577d410bd527bd8df08f61906';

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

/// 需求：UC-004 從 session 列表中解析 session 顯示名稱
/// 約束：sessionId 為 null 時回傳空字串，找不到或 agentName 為空時 fallback 為 sessionId
///
/// Copied from [sessionName].
@ProviderFor(sessionName)
const sessionNameProvider = SessionNameFamily();

/// 需求：UC-004 從 session 列表中解析 session 顯示名稱
/// 約束：sessionId 為 null 時回傳空字串，找不到或 agentName 為空時 fallback 為 sessionId
///
/// Copied from [sessionName].
class SessionNameFamily extends Family<String> {
  /// 需求：UC-004 從 session 列表中解析 session 顯示名稱
  /// 約束：sessionId 為 null 時回傳空字串，找不到或 agentName 為空時 fallback 為 sessionId
  ///
  /// Copied from [sessionName].
  const SessionNameFamily();

  /// 需求：UC-004 從 session 列表中解析 session 顯示名稱
  /// 約束：sessionId 為 null 時回傳空字串，找不到或 agentName 為空時 fallback 為 sessionId
  ///
  /// Copied from [sessionName].
  SessionNameProvider call({required String? sessionId}) {
    return SessionNameProvider(sessionId: sessionId);
  }

  @override
  SessionNameProvider getProviderOverride(
    covariant SessionNameProvider provider,
  ) {
    return call(sessionId: provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sessionNameProvider';
}

/// 需求：UC-004 從 session 列表中解析 session 顯示名稱
/// 約束：sessionId 為 null 時回傳空字串，找不到或 agentName 為空時 fallback 為 sessionId
///
/// Copied from [sessionName].
class SessionNameProvider extends AutoDisposeProvider<String> {
  /// 需求：UC-004 從 session 列表中解析 session 顯示名稱
  /// 約束：sessionId 為 null 時回傳空字串，找不到或 agentName 為空時 fallback 為 sessionId
  ///
  /// Copied from [sessionName].
  SessionNameProvider({required String? sessionId})
    : this._internal(
        (ref) => sessionName(ref as SessionNameRef, sessionId: sessionId),
        from: sessionNameProvider,
        name: r'sessionNameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sessionNameHash,
        dependencies: SessionNameFamily._dependencies,
        allTransitiveDependencies: SessionNameFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  SessionNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String? sessionId;

  @override
  Override overrideWith(String Function(SessionNameRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: SessionNameProvider._internal(
        (ref) => create(ref as SessionNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _SessionNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionNameProvider && other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SessionNameRef on AutoDisposeProviderRef<String> {
  /// The parameter `sessionId` of this provider.
  String? get sessionId;
}

class _SessionNameProviderElement extends AutoDisposeProviderElement<String>
    with SessionNameRef {
  _SessionNameProviderElement(super.provider);

  @override
  String? get sessionId => (origin as SessionNameProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
