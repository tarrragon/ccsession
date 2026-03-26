import 'dart:async';

import 'package:ccsession/core/models/server_message.dart';
import 'package:ccsession/core/websocket/websocket_provider.dart';
import 'package:ccsession/core/websocket/websocket_service.dart';
import 'package:ccsession/features/conversation/domain/search_match.dart';
import 'package:ccsession/features/conversation/presentation/conversation_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_notifier.dart';
import 'package:ccsession/features/conversation/presentation/conversation_search_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_conversation_factory.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

Future<void> _pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  group('TG-SEARCH-NOTIFIER: ConversationSearchNotifier', () {
    late ProviderContainer container;
    late StreamController<ServerMessage> messageController;
    late MockWebSocketService mockService;

    setUp(() {
      messageController = StreamController<ServerMessage>.broadcast();
      mockService = MockWebSocketService();
      when(() => mockService.messageStream)
          .thenAnswer((_) => messageController.stream);
      when(() => mockService.requestSessionHistory(
            any(),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
          )).thenReturn(null);
      when(() => mockService.subscribeSession(any())).thenReturn(null);
      when(() => mockService.unsubscribeSession(any())).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          webSocketServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      messageController.close();
    });

    Future<void> initNotifier() async {
      container.listen(conversationNotifierProvider, (_, __) {});
      container.listen(conversationSearchNotifierProvider, (_, __) {});
      await _pump();
    }

    Future<void> loadEventsIntoSession(List<dynamic> events) async {
      container.read(conversationNotifierProvider.notifier).loadSession('session-1');
      await _pump();
      final sessionEvents = events.map((e) {
        if (e is String) return createUserEvent(e, sessionId: 'session-1');
        return e;
      }).toList();
      messageController.add(createSessionHistoryMessage(
        'session-1',
        sessionEvents.cast(),
      ));
      await _pump();
    }

    ConversationSearchState getSearchState() {
      return container.read(conversationSearchNotifierProvider);
    }

    Future<void> updateQueryAndWait(String query) async {
      container
          .read(conversationSearchNotifierProvider.notifier)
          .updateQuery(query);
      // Wait for debounce (300ms) + margin
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }

    // TC-SEARCH-20: openSearch
    test('TC-SEARCH-20: openSearch sets isSearchVisible to true', () async {
      await initNotifier();

      // 前置驗證
      expect(getSearchState().isSearchVisible, isFalse);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();

      expect(getSearchState().isSearchVisible, isTrue);
      expect(getSearchState().query, isEmpty);
      expect(getSearchState().matches, isEmpty);
      expect(getSearchState().currentMatchIndex, equals(-1));
    });

    // TC-SEARCH-21: closeSearch
    test('TC-SEARCH-21: closeSearch resets all state', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('hello error', sessionId: 'session-1'),
        createAssistantEvent('no error here', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('error');

      // 前置驗證
      expect(getSearchState().isSearchVisible, isTrue);
      expect(getSearchState().matches, isNotEmpty);

      container.read(conversationSearchNotifierProvider.notifier).closeSearch();

      expect(getSearchState().isSearchVisible, isFalse);
      expect(getSearchState().query, isEmpty);
      expect(getSearchState().matches, isEmpty);
      expect(getSearchState().currentMatchIndex, equals(-1));
    });

    // TC-SEARCH-22: updateQuery normal match
    test('TC-SEARCH-22: updateQuery finds matches across events', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('hello error', sessionId: 'session-1'),
        createAssistantEvent('no error here', sessionId: 'session-1'),
        createUserEvent('ok', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('error');

      final state = getSearchState();
      expect(state.matches.length, equals(2));
      expect(state.currentMatchIndex, equals(0));
      expect(state.matches[0].eventIndex, equals(0));
      expect(state.matches[1].eventIndex, equals(1));
    });

    // TC-SEARCH-23: case insensitive
    test('TC-SEARCH-23: updateQuery is case-insensitive', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('Error', sessionId: 'session-1'),
        createAssistantEvent('ERROR', sessionId: 'session-1'),
        createUserEvent('error', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('error');

      expect(getSearchState().matches.length, equals(3));
    });

    // TC-SEARCH-24: no match
    test('TC-SEARCH-24: updateQuery with no match shows 0/0', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('hello', sessionId: 'session-1'),
        createAssistantEvent('world', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('xyz');

      final state = getSearchState();
      expect(state.matches, isEmpty);
      expect(state.currentMatchIndex, equals(-1));
      expect(state.matchCountDisplay, equals('0/0'));
    });

    // TC-SEARCH-25: empty query clears results
    test('TC-SEARCH-25: empty query clears matches', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('hello error', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('error');

      // 前置驗證
      expect(getSearchState().matches, isNotEmpty);

      await updateQueryAndWait('');

      expect(getSearchState().matches, isEmpty);
      expect(getSearchState().matchCountDisplay, isEmpty);
    });

    // TC-SEARCH-26: debounce behavior
    test('TC-SEARCH-26: debounce only triggers search on last query',
        () async {
      fakeAsync((async) {
        final localContainer = ProviderContainer(
          overrides: [
            webSocketServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(localContainer.dispose);

        localContainer.listen(conversationNotifierProvider, (_, __) {});
        localContainer.listen(conversationSearchNotifierProvider, (_, __) {});
        async.elapse(const Duration(milliseconds: 50));

        // Load events
        localContainer
            .read(conversationNotifierProvider.notifier)
            .loadSession('session-1');
        async.elapse(const Duration(milliseconds: 50));

        final events = [
          createUserEvent('error err e', sessionId: 'session-1'),
        ];
        messageController.add(createSessionHistoryMessage('session-1', events));
        async.elapse(const Duration(milliseconds: 50));

        localContainer
            .read(conversationSearchNotifierProvider.notifier)
            .openSearch();

        // Rapid calls < 300ms apart
        localContainer
            .read(conversationSearchNotifierProvider.notifier)
            .updateQuery('e');
        async.elapse(const Duration(milliseconds: 100));
        localContainer
            .read(conversationSearchNotifierProvider.notifier)
            .updateQuery('er');
        async.elapse(const Duration(milliseconds: 100));
        localContainer
            .read(conversationSearchNotifierProvider.notifier)
            .updateQuery('err');
        async.elapse(const Duration(milliseconds: 400));

        final state = localContainer.read(conversationSearchNotifierProvider);
        // "err" matches in "error err e" at positions 0 and 6
        expect(state.query, equals('err'));
        expect(state.matches.length, equals(2));
      });
    });

    // TC-SEARCH-27: single event multiple matches
    test('TC-SEARCH-27: single event with multiple matches', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('error in error handling', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('error');

      final state = getSearchState();
      expect(state.matches.length, equals(2));
      expect(state.matches[0].eventIndex, equals(0));
      expect(state.matches[1].eventIndex, equals(0));
      expect(state.matches[0].startOffset, equals(0));
      expect(state.matches[1].startOffset, equals(9));
    });

    // TC-SEARCH-28: tool_use search toolName
    test('TC-SEARCH-28: searches tool_use toolName field', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createToolUseEvent('Read', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('Read');

      final state = getSearchState();
      expect(state.matches.length, equals(1));
      expect(state.matches[0].field, equals('toolName'));
    });

    // TC-SEARCH-29: tool_result search output
    test('TC-SEARCH-29: searches tool_result output field', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createToolResultEvent(
          output: 'contents of main.dart',
          sessionId: 'session-1',
        ),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('main.dart');

      final state = getSearchState();
      expect(state.matches.length, equals(1));
      expect(state.matches[0].field, equals('output'));
    });

    // TC-SEARCH-30: nextMatch normal navigation
    test('TC-SEARCH-30: nextMatch increments currentMatchIndex', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('a a a a a', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('a');

      // 前置驗證
      expect(getSearchState().currentMatchIndex, equals(0));
      expect(getSearchState().matches.length, equals(5));

      container.read(conversationSearchNotifierProvider.notifier).nextMatch();

      expect(getSearchState().currentMatchIndex, equals(1));
    });

    // TC-SEARCH-31: nextMatch wraps to first
    test('TC-SEARCH-31: nextMatch wraps from last to first', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('a a a a a', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('a');

      // Navigate to last
      for (var i = 0; i < 4; i++) {
        container.read(conversationSearchNotifierProvider.notifier).nextMatch();
      }

      // 前置驗證
      expect(getSearchState().currentMatchIndex, equals(4));

      container.read(conversationSearchNotifierProvider.notifier).nextMatch();

      expect(getSearchState().currentMatchIndex, equals(0));
    });

    // TC-SEARCH-32: previousMatch wraps to last
    test('TC-SEARCH-32: previousMatch wraps from first to last', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('a b a', sessionId: 'session-1'),
        createUserEvent('a', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('a');

      // 前置驗證
      expect(getSearchState().currentMatchIndex, equals(0));

      container
          .read(conversationSearchNotifierProvider.notifier)
          .previousMatch();

      expect(
        getSearchState().currentMatchIndex,
        equals(getSearchState().matches.length - 1),
      );
    });

    // TC-SEARCH-33: previousMatch normal navigation
    test('TC-SEARCH-33: previousMatch decrements currentMatchIndex', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('a b a', sessionId: 'session-1'),
        createUserEvent('a', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('a');

      // Navigate to index 2
      container.read(conversationSearchNotifierProvider.notifier).nextMatch();
      container.read(conversationSearchNotifierProvider.notifier).nextMatch();
      expect(getSearchState().currentMatchIndex, equals(2));

      container
          .read(conversationSearchNotifierProvider.notifier)
          .previousMatch();

      expect(getSearchState().currentMatchIndex, equals(1));
    });

    // TC-SEARCH-34: next/previous with no matches
    test('TC-SEARCH-34: nextMatch and previousMatch do nothing when no matches',
        () async {
      await initNotifier();

      container.read(conversationSearchNotifierProvider.notifier).openSearch();

      // 前置驗證
      expect(getSearchState().matches, isEmpty);
      expect(getSearchState().currentMatchIndex, equals(-1));

      container.read(conversationSearchNotifierProvider.notifier).nextMatch();
      expect(getSearchState().currentMatchIndex, equals(-1));

      container
          .read(conversationSearchNotifierProvider.notifier)
          .previousMatch();
      expect(getSearchState().currentMatchIndex, equals(-1));
    });

    // TC-SEARCH-35: events change triggers re-search
    test('TC-SEARCH-35: new event triggers automatic re-search', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('test one', sessionId: 'session-1'),
        createAssistantEvent('test two', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('test');

      // 前置驗證
      expect(getSearchState().matches.length, equals(2));

      // Add new event with "test"
      messageController.add(createSessionEventMessage(
        createAssistantEvent('test three', sessionId: 'session-1'),
      ));
      await _pump();
      await _pump();

      expect(getSearchState().matches.length, equals(3));
    });

    // TC-SEARCH-36: session switch resets search
    test('TC-SEARCH-36: session switch resets search state', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('hello', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('hello');

      // 前置驗證
      expect(getSearchState().isSearchVisible, isTrue);
      expect(getSearchState().matches, isNotEmpty);

      // Simulate session switch by leaving session (clears events)
      container.read(conversationNotifierProvider.notifier).leaveSession();
      await _pump();

      expect(getSearchState().isSearchVisible, isFalse);
      expect(getSearchState().query, isEmpty);
      expect(getSearchState().matches, isEmpty);
    });

    // TC-SEARCH-37: matchCountDisplay derived property
    test('TC-SEARCH-37: matchCountDisplay shows correct format', () {
      // Case 1: empty query
      const emptyQuery = ConversationSearchState(query: '');
      expect(emptyQuery.matchCountDisplay, isEmpty);

      // Case 2: no matches
      const noMatch = ConversationSearchState(query: 'xyz');
      expect(noMatch.matchCountDisplay, equals('0/0'));

      // Case 3: with matches
      const withMatches = ConversationSearchState(
        query: 'error',
        matches: [
          SearchMatch(eventIndex: 0, startOffset: 0, endOffset: 5, field: 'text'),
          SearchMatch(eventIndex: 1, startOffset: 0, endOffset: 5, field: 'text'),
          SearchMatch(eventIndex: 2, startOffset: 0, endOffset: 5, field: 'text'),
          SearchMatch(eventIndex: 3, startOffset: 0, endOffset: 5, field: 'text'),
          SearchMatch(eventIndex: 4, startOffset: 0, endOffset: 5, field: 'text'),
        ],
        currentMatchIndex: 2,
      );
      expect(withMatches.matchCountDisplay, equals('3/5'));
    });

    // TC-SEARCH-38: currentMatch derived property
    test('TC-SEARCH-38: currentMatch returns correct match or null', () {
      // Case 1: no match
      const noMatch = ConversationSearchState(currentMatchIndex: -1);
      expect(noMatch.currentMatch, isNull);

      // Case 2: with match
      const match = SearchMatch(
        eventIndex: 0,
        startOffset: 0,
        endOffset: 5,
        field: 'text',
      );
      const withMatch = ConversationSearchState(
        matches: [match, match, match],
        currentMatchIndex: 0,
      );
      expect(withMatch.currentMatch, equals(match));
    });

    // TC-SEARCH-39: single character search
    test('TC-SEARCH-39: single character search works', () async {
      await initNotifier();
      await loadEventsIntoSession([
        createUserEvent('a', sessionId: 'session-1'),
        createAssistantEvent('b', sessionId: 'session-1'),
        createUserEvent('a', sessionId: 'session-1'),
      ]);

      container.read(conversationSearchNotifierProvider.notifier).openSearch();
      await updateQueryAndWait('a');

      expect(getSearchState().matches.length, equals(2));
    });
  });
}
