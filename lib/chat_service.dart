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
    );
  }

  final String id;
  final String text;
  final String senderId;
  final String senderName;

  /// Null while the server timestamp for a just-sent message is still pending.
  final DateTime? createdAt;
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
