import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth/auth_service.dart';

/// A single chat message inside a group's chat room.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.type = 'user',
  });

  factory ChatMessage.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final rawCreatedAt = data['createdAt'];
    return ChatMessage(
      id: snapshot.id,
      text: data['text']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '학생',
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
      type: data['type']?.toString() == 'system' ? 'system' : 'user',
    );
  }

  final String id;
  final String text;
  final String senderId;
  final String senderName;

  /// Null while the server timestamp for a just-sent message is still pending.
  final DateTime? createdAt;

  /// 'user'(일반 메시지) 또는 'system'(참여/이탈 안내).
  final String type;

  bool get isSystem => type == 'system';
}

/// Read/write access to a group's realtime chat messages.
abstract interface class ChatService {
  Stream<List<ChatMessage>> watchMessages(String groupId);

  Future<void> sendMessage({
    required String groupId,
    required String text,
    required String senderId,
  });
}

/// Firestore-backed [ChatService].
///
/// Messages live in the `messages` subcollection of each `group` document,
/// so a group and its chat room map one-to-one without a separate room doc.
class FirestoreChatService implements ChatService {
  FirestoreChatService._();

  static final FirestoreChatService instance = FirestoreChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _displayNameCache = <String, String>{};

  CollectionReference<Map<String, dynamic>> _messagesRef(String groupId) =>
      _firestore.collection('group').doc(groupId).collection('messages');

  @override
  Stream<List<ChatMessage>> watchMessages(String groupId) {
    return _messagesRef(groupId).orderBy('createdAt').snapshots().map((
      snapshot,
    ) {
      final messages = snapshot.docs.map(ChatMessage.fromSnapshot).toList();
      // A just-sent message has no server timestamp yet; keep it last so it
      // stays pinned to the bottom instead of jumping to the top.
      messages.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) {
          return 0;
        }
        if (aTime == null) {
          return 1;
        }
        if (bTime == null) {
          return -1;
        }
        return aTime.compareTo(bTime);
      });
      return messages;
    });
  }

  @override
  Future<void> sendMessage({
    required String groupId,
    required String text,
    required String senderId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final senderName = await _resolveDisplayName(senderId);
    await _messagesRef(groupId).add({
      'text': trimmed,
      'senderId': senderId,
      'senderName': senderName,
      'type': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 멤버 참여/이탈을 채팅방에 시스템 메시지로 남긴다.
  Future<void> postMembershipNotice({
    required String groupId,
    required String uid,
    required bool joined,
  }) async {
    final name = await _resolveDisplayName(uid);
    final text = joined ? '$name님이 참여했어요.' : '$name님이 그룹에서 나갔어요.';
    await _messagesRef(groupId).add({
      'text': text,
      'senderId': uid,
      'senderName': name,
      'type': 'system',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _resolveDisplayName(String uid) async {
    final cached = _displayNameCache[uid];
    if (cached != null) {
      return cached;
    }

    final snapshot = await AuthService.instance.profileRef(uid).get();
    final displayName = snapshot.data()?['displayName']?.toString().trim();
    final resolved = (displayName == null || displayName.isEmpty)
        ? '학생'
        : displayName;
    _displayNameCache[uid] = resolved;
    return resolved;
  }
}
