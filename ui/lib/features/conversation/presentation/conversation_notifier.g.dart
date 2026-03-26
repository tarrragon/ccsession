// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationNotifierHash() =>
    r'7a7ea6e2c732edd7fc6b656d01df1a6f4dde4db7';

/// 需求：管理 session 對話狀態，消費 WebSocket 訊息
/// 約束：使用 @riverpod code generation，與 SessionListNotifier 模式一致
///
/// Copied from [ConversationNotifier].
@ProviderFor(ConversationNotifier)
final conversationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ConversationNotifier,
      ConversationState
    >.internal(
      ConversationNotifier.new,
      name: r'conversationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConversationNotifier = AutoDisposeAsyncNotifier<ConversationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
