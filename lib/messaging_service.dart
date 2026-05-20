import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'auth/auth_service.dart';

/// FCM 푸시 알림 등록·토큰 관리 싱글턴.
///
/// 로그인 직후 [registerForUser]를 호출하면 사용자에게 알림 권한을 요청하고
/// 발급된 FCM 토큰을 `users/{uid}.fcmTokens` 배열에 누적 저장한다. 토큰이
/// 갱신될 때마다 자동으로 다시 저장된다. APNs/Cloud Functions 미구성 환경에서
/// 호출되어도 앱이 죽지 않도록 모든 실패를 조용히 흡수한다.
class MessagingService {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenSub;
  String? _registeredUid;

  /// 로그인 직후 한 번 호출. 권한 거부 시 조용히 종료한다.
  Future<void> registerForUser(String uid) async {
    if (uid.isEmpty || uid == _registeredUid) {
      return;
    }
    try {
      final settings = await _fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(uid, token);
      }
      await _tokenSub?.cancel();
      _tokenSub = _fcm.onTokenRefresh.listen((next) async {
        try {
          await _saveToken(uid, next);
        } on FirebaseException {
          // 토큰 갱신 저장 실패는 무시한다(다음 갱신/재로그인에 재시도).
        }
      });
      _registeredUid = uid;
    } on FirebaseException {
      // APNs 미설정 / Cloud Messaging 미활성 / 네트워크 오류 등은 무시한다.
    }
  }

  /// 로그아웃 시 호출. 토큰 리스너를 해제하고, 이 기기의 현재 FCM 토큰을
  /// 직전 사용자의 `users/{uid}.fcmTokens` 배열에서 제거해 계정 전환 후
  /// 이전 사용자에게 알림이 가지 않도록 한다.
  Future<void> unregister() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    final uid = _registeredUid;
    _registeredUid = null;
    if (uid == null || uid.isEmpty) {
      return;
    }
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      await AuthService.instance.profileRef(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // 토큰 정리 실패는 로그아웃 자체를 막지 않는다.
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await AuthService.instance.profileRef(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
