import 'package:ccsession/core/models/session_info.dart';
import 'package:ccsession/features/session_list/presentation/session_list_notifier.dart';
import 'package:ccsession/features/split_view/presentation/session_name_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sessionNameProvider', () {
    /// 需求：UC-004 sessionId 為 null 時回傳空字串
    test('returns empty string when sessionId is null', () {
      final container = ProviderContainer(
        overrides: [
          sessionListNotifierProvider.overrideWith(
            () => _FakeSessionListNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(sessionNameProvider(sessionId: null));
      expect(result, '');
    });

    /// 需求：UC-004 session 列表尚未載入時 fallback 為 sessionId
    test('returns sessionId when session list is not loaded', () {
      final container = ProviderContainer(
        overrides: [
          sessionListNotifierProvider.overrideWith(
            () => _LoadingSessionListNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(sessionNameProvider(sessionId: 'abc-123'));
      expect(result, 'abc-123');
    });

    /// 需求：UC-004 找不到 session 時 fallback 為 sessionId
    test('returns sessionId when session not found in list', () {
      final container = ProviderContainer(
        overrides: [
          sessionListNotifierProvider.overrideWith(
            () => _FakeSessionListNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result =
          container.read(sessionNameProvider(sessionId: 'not-exist'));
      expect(result, 'not-exist');
    });

    /// 需求：UC-004 找到 session 且 agentName 非空時回傳 agentName
    test('returns agentName when session found with non-empty name', () async {
      final container = ProviderContainer(
        overrides: [
          sessionListNotifierProvider.overrideWith(
            () => _FakeSessionListNotifier(sessions: [_makeSession('s1', agentName: 'My Agent')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 等待 sessionListNotifier 完成載入
      await container.read(sessionListNotifierProvider.future);

      final result = container.read(sessionNameProvider(sessionId: 's1'));
      expect(result, 'My Agent');
    });

    /// 需求：UC-004 找到 session 但 agentName 為空時 fallback 為 sessionId
    test('returns sessionId when agentName is empty', () async {
      final container = ProviderContainer(
        overrides: [
          sessionListNotifierProvider.overrideWith(
            () => _FakeSessionListNotifier(sessions: [_makeSession('s2')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(sessionListNotifierProvider.future);

      final result = container.read(sessionNameProvider(sessionId: 's2'));
      expect(result, 's2');
    });
  });
}

SessionInfo _makeSession(String id, {String agentName = ''}) {
  final now = DateTime.now();
  return SessionInfo(
    id: id,
    projectPath: '/tmp',
    status: SessionStatus.active,
    firstEventAt: now,
    lastEventAt: now,
    agentName: agentName,
  );
}

/// 已載入空列表的 Fake
class _FakeSessionListNotifier extends SessionListNotifier {
  _FakeSessionListNotifier({this.sessions = const []});

  final List<SessionInfo> sessions;

  @override
  Future<SessionListState> build() async => SessionListState(sessions: sessions);
}

/// 永遠處於 loading 狀態的 Fake
class _LoadingSessionListNotifier extends SessionListNotifier {
  @override
  Future<SessionListState> build() {
    // 永不完成，保持 AsyncLoading 狀態
    return Future<SessionListState>.delayed(const Duration(days: 1));
  }
}
