import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage에 사용자 프로필 사진을 업로드/삭제하는 헬퍼.
class ProfileStorage {
  ProfileStorage._();

  static final ProfileStorage instance = ProfileStorage._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Reference _avatarRef(String uid) =>
      _storage.ref().child('users/$uid/avatar.jpg');

  Future<String> uploadAvatar({required String uid, required File file}) async {
    final ref = _avatarRef(uid);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> deleteAvatar(String uid) async {
    try {
      await _avatarRef(uid).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }
}
