import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluttertest/chat_page.dart';
import 'package:fluttertest/chat_service.dart';

/// In-memory [ChatService] so [ChatPage] can be tested without Firestore.
class _FakeChatService implements ChatService {
  _FakeChatService(this._messages);

  final List<ChatMessage> _messages;
  final List<String> sentTexts = <String>[];

  @override
  Stream<List<ChatMessage>> watchMessages(String groupId) =>
      Stream.value(_messages);

  @override
  Future<void> sendMessage({
    required String groupId,
    required String text,
    required String senderId,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }
    sentTexts.add(text);
  }
}

ChatMessage _message(String id, String text, String senderId) => ChatMessage(
  id: id,
  text: text,
  senderId: senderId,
  senderName: senderId == 'me' ? '나' : '상대',
  createdAt: DateTime(2026, 5, 20, 9, 41),
);

Widget _wrap(ChatService service, {String currentUserId = 'me'}) {
  return MaterialApp(
    home: ChatPage(
      groupId: 'g1',
      groupName: '테스트 그룹',
      memberCount: 2,
      currentUserId: currentUserId,
      service: service,
    ),
  );
}

void main() {
  testWidgets('renders messages and group name from the service', (
    tester,
  ) async {
    final service = _FakeChatService([
      _message('1', '안녕하세요', 'other'),
      _message('2', '반가워요', 'me'),
    ]);

    await tester.pumpWidget(_wrap(service));
    await tester.pump();

    expect(find.text('테스트 그룹'), findsOneWidget);
    expect(find.text('안녕하세요'), findsOneWidget);
    expect(find.text('반가워요'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no messages', (tester) async {
    await tester.pumpWidget(_wrap(_FakeChatService(<ChatMessage>[])));
    await tester.pump();

    expect(find.text('No messages yet.\nSend the first one.'), findsOneWidget);
  });

  testWidgets('does not send blank messages but sends real ones', (
    tester,
  ) async {
    final service = _FakeChatService(<ChatMessage>[]);

    await tester.pumpWidget(_wrap(service));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byKey(const ValueKey('chat-send-button')));
    await tester.pump();
    expect(service.sentTexts, isEmpty);

    await tester.enterText(find.byType(TextField), '실제 메시지');
    await tester.tap(find.byKey(const ValueKey('chat-send-button')));
    await tester.pump();
    expect(service.sentTexts, <String>['실제 메시지']);
  });
}
