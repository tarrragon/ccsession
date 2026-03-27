// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filtered_grouped_sessions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredGroupedSessionsHash() =>
    r'ea660fb3084b5076e918164b445382d0ac554322';

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

/// 需求：[0.2.0-W4-003] 篩選後的分組 session 列表（computed provider）
/// 約束：依賴 sessionListNotifier 和 searchNotifier，任一變化自動重算
/// 約束：空 query（trim 後）回傳完整列表；非空則 case-insensitive contains
/// 約束：若指定 projectPath，先按 projectPath 過濾
///
/// Copied from [filteredGroupedSessions].
@ProviderFor(filteredGroupedSessions)
const filteredGroupedSessionsProvider = FilteredGroupedSessionsFamily();

/// 需求：[0.2.0-W4-003] 篩選後的分組 session 列表（computed provider）
/// 約束：依賴 sessionListNotifier 和 searchNotifier，任一變化自動重算
/// 約束：空 query（trim 後）回傳完整列表；非空則 case-insensitive contains
/// 約束：若指定 projectPath，先按 projectPath 過濾
///
/// Copied from [filteredGroupedSessions].
class FilteredGroupedSessionsFamily
    extends Family<Map<SessionStatus, List<SessionInfo>>> {
  /// 需求：[0.2.0-W4-003] 篩選後的分組 session 列表（computed provider）
  /// 約束：依賴 sessionListNotifier 和 searchNotifier，任一變化自動重算
  /// 約束：空 query（trim 後）回傳完整列表；非空則 case-insensitive contains
  /// 約束：若指定 projectPath，先按 projectPath 過濾
  ///
  /// Copied from [filteredGroupedSessions].
  const FilteredGroupedSessionsFamily();

  /// 需求：[0.2.0-W4-003] 篩選後的分組 session 列表（computed provider）
  /// 約束：依賴 sessionListNotifier 和 searchNotifier，任一變化自動重算
  /// 約束：空 query（trim 後）回傳完整列表；非空則 case-insensitive contains
  /// 約束：若指定 projectPath，先按 projectPath 過濾
  ///
  /// Copied from [filteredGroupedSessions].
  FilteredGroupedSessionsProvider call({String? projectPath}) {
    return FilteredGroupedSessionsProvider(projectPath: projectPath);
  }

  @override
  FilteredGroupedSessionsProvider getProviderOverride(
    covariant FilteredGroupedSessionsProvider provider,
  ) {
    return call(projectPath: provider.projectPath);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredGroupedSessionsProvider';
}

/// 需求：[0.2.0-W4-003] 篩選後的分組 session 列表（computed provider）
/// 約束：依賴 sessionListNotifier 和 searchNotifier，任一變化自動重算
/// 約束：空 query（trim 後）回傳完整列表；非空則 case-insensitive contains
/// 約束：若指定 projectPath，先按 projectPath 過濾
///
/// Copied from [filteredGroupedSessions].
class FilteredGroupedSessionsProvider
    extends AutoDisposeProvider<Map<SessionStatus, List<SessionInfo>>> {
  /// 需求：[0.2.0-W4-003] 篩選後的分組 session 列表（computed provider）
  /// 約束：依賴 sessionListNotifier 和 searchNotifier，任一變化自動重算
  /// 約束：空 query（trim 後）回傳完整列表；非空則 case-insensitive contains
  /// 約束：若指定 projectPath，先按 projectPath 過濾
  ///
  /// Copied from [filteredGroupedSessions].
  FilteredGroupedSessionsProvider({String? projectPath})
    : this._internal(
        (ref) => filteredGroupedSessions(
          ref as FilteredGroupedSessionsRef,
          projectPath: projectPath,
        ),
        from: filteredGroupedSessionsProvider,
        name: r'filteredGroupedSessionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$filteredGroupedSessionsHash,
        dependencies: FilteredGroupedSessionsFamily._dependencies,
        allTransitiveDependencies:
            FilteredGroupedSessionsFamily._allTransitiveDependencies,
        projectPath: projectPath,
      );

  FilteredGroupedSessionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectPath,
  }) : super.internal();

  final String? projectPath;

  @override
  Override overrideWith(
    Map<SessionStatus, List<SessionInfo>> Function(
      FilteredGroupedSessionsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredGroupedSessionsProvider._internal(
        (ref) => create(ref as FilteredGroupedSessionsRef),
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
  AutoDisposeProviderElement<Map<SessionStatus, List<SessionInfo>>>
  createElement() {
    return _FilteredGroupedSessionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredGroupedSessionsProvider &&
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
mixin FilteredGroupedSessionsRef
    on AutoDisposeProviderRef<Map<SessionStatus, List<SessionInfo>>> {
  /// The parameter `projectPath` of this provider.
  String? get projectPath;
}

class _FilteredGroupedSessionsProviderElement
    extends AutoDisposeProviderElement<Map<SessionStatus, List<SessionInfo>>>
    with FilteredGroupedSessionsRef {
  _FilteredGroupedSessionsProviderElement(super.provider);

  @override
  String? get projectPath =>
      (origin as FilteredGroupedSessionsProvider).projectPath;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
