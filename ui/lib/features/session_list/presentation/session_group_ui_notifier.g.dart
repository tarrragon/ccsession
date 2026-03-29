// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_group_ui_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionGroupUiNotifierHash() =>
    r'c08e04a39ec93d62eef025c0663aef818a4d6dfd';

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

abstract class _$SessionGroupUiNotifier
    extends BuildlessAutoDisposeNotifier<SessionGroupUiState> {
  late final String projectPath;

  SessionGroupUiState build(String projectPath);
}

/// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
/// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
///
/// Copied from [SessionGroupUiNotifier].
@ProviderFor(SessionGroupUiNotifier)
const sessionGroupUiNotifierProvider = SessionGroupUiNotifierFamily();

/// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
/// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
///
/// Copied from [SessionGroupUiNotifier].
class SessionGroupUiNotifierFamily extends Family<SessionGroupUiState> {
  /// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
  /// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
  ///
  /// Copied from [SessionGroupUiNotifier].
  const SessionGroupUiNotifierFamily();

  /// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
  /// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
  ///
  /// Copied from [SessionGroupUiNotifier].
  SessionGroupUiNotifierProvider call(String projectPath) {
    return SessionGroupUiNotifierProvider(projectPath);
  }

  @override
  SessionGroupUiNotifierProvider getProviderOverride(
    covariant SessionGroupUiNotifierProvider provider,
  ) {
    return call(provider.projectPath);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sessionGroupUiNotifierProvider';
}

/// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
/// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
///
/// Copied from [SessionGroupUiNotifier].
class SessionGroupUiNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          SessionGroupUiNotifier,
          SessionGroupUiState
        > {
  /// 需求：[0.2.1-W2-002] 管理分頁索引和摺疊狀態
  /// 約束：@riverpod Notifier，狀態不持久化（記憶體即可）
  ///
  /// Copied from [SessionGroupUiNotifier].
  SessionGroupUiNotifierProvider(String projectPath)
    : this._internal(
        () => SessionGroupUiNotifier()..projectPath = projectPath,
        from: sessionGroupUiNotifierProvider,
        name: r'sessionGroupUiNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sessionGroupUiNotifierHash,
        dependencies: SessionGroupUiNotifierFamily._dependencies,
        allTransitiveDependencies:
            SessionGroupUiNotifierFamily._allTransitiveDependencies,
        projectPath: projectPath,
      );

  SessionGroupUiNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectPath,
  }) : super.internal();

  final String projectPath;

  @override
  SessionGroupUiState runNotifierBuild(
    covariant SessionGroupUiNotifier notifier,
  ) {
    return notifier.build(projectPath);
  }

  @override
  Override overrideWith(SessionGroupUiNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SessionGroupUiNotifierProvider._internal(
        () => create()..projectPath = projectPath,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectPath: projectPath,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    SessionGroupUiNotifier,
    SessionGroupUiState
  >
  createElement() {
    return _SessionGroupUiNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionGroupUiNotifierProvider &&
        other.projectPath == projectPath;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectPath.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SessionGroupUiNotifierRef
    on AutoDisposeNotifierProviderRef<SessionGroupUiState> {
  /// The parameter `projectPath` of this provider.
  String get projectPath;
}

class _SessionGroupUiNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          SessionGroupUiNotifier,
          SessionGroupUiState
        >
    with SessionGroupUiNotifierRef {
  _SessionGroupUiNotifierProviderElement(super.provider);

  @override
  String get projectPath =>
      (origin as SessionGroupUiNotifierProvider).projectPath;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
