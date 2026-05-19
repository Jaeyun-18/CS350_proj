# Phase 6 — FCM 푸시 알림 핸드오프

`기능명세서` 7.3 "푸시 알림(FCM)"은 클라이언트 코드만으로 동작시킬 수 없는
부분이라 이 문서로 인계합니다. 아래 6단계가 끝나면 채팅·그룹 상태 변경 시
실기기에서 푸시 알림이 도착합니다.

## 왜 클라이언트 코드만으로 안 되나

- 클라이언트는 다른 사용자에게 직접 푸시를 보낼 수 없음(보안).
  새 메시지·그룹 상태 변경 등 트리거로 FCM을 발송하려면 **서버(Cloud
  Functions)** 가 필수.
- iOS는 **Apple APNs 인증서/키**가 Firebase Console에 등록되어야 발송됨.
- Cloud Functions의 외부 네트워크 발신(FCM HTTP/v1)은 Firebase
  **Blaze(종량제) 플랜**에서만 가능.

## 1단계: Apple Developer + Firebase Console

1. Apple Developer 콘솔에서 **APNs Auth Key(.p8)** 발급, Key ID·Team ID 메모.
2. Firebase Console → 프로젝트 `flutter-firebase-test-4b17c` → Project
   settings → **Cloud Messaging** → Apple app configuration에 .p8 키 업로드.
3. Firebase Console → Build → **Cloud Messaging API**가 사용 설정인지 확인.
4. 결제 플랜을 **Blaze**로 업그레이드(Cloud Functions 외부 발신 필요).

## 2단계: Xcode 권한

`ios/Runner.xcworkspace` 열고 Runner target → **Signing & Capabilities**에
다음을 추가:

- **Push Notifications** capability
- **Background Modes** → "Remote notifications" 체크

## 3단계: Flutter 의존성

`pubspec.yaml`의 `dependencies:`에 추가(최신 메이저 버전 확인 후 사용):

```yaml
  firebase_messaging: ^16.0.0
```

이어서:

```bash
flutter pub get
cd ios && pod install && cd ..
```

## 4단계: 클라이언트 코드(템플릿)

`lib/messaging_service.dart` 신규:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'auth/auth_service.dart';

class MessagingService {
  MessagingService._();
  static final instance = MessagingService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// 로그인 직후 호출 — 권한 요청 + 토큰을 users/{uid}.fcmTokens 에 저장.
  Future<void> registerForUser(String uid) async {
    final settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }
    final token = await _fcm.getToken();
    if (token == null) return;
    await _saveToken(uid, token);
    _fcm.onTokenRefresh.listen((next) => _saveToken(uid, next));
  }

  Future<void> _saveToken(String uid, String token) async {
    await AuthService.instance.profileRef(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
```

`lib/main_page.dart`의 `_MainPageState.initState`에 추가:

```dart
unawaited(MessagingService.instance.registerForUser(widget.user.uid));
```

(import: `dart:async`의 `unawaited`, `messaging_service.dart`)

## 5단계: Cloud Functions (서버)

```bash
firebase init functions   # TypeScript 권장
```

`functions/src/index.ts`:

```ts
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

initializeApp();
const db = getFirestore();
const msg = getMessaging();

export const onChatMessage = onDocumentCreated(
  'group/{groupId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message || message.type !== 'user') return;
    const groupId = event.params.groupId;
    const group = await db.doc(`group/${groupId}`).get();
    const memberIds: string[] = group.get('member_ids') ?? [];
    const targets = memberIds.filter((id) => id !== message.senderId);
    if (targets.length === 0) return;

    const userSnaps = await db.getAll(
      ...targets.map((id) => db.doc(`users/${id}`)),
    );
    const tokens = userSnaps.flatMap(
      (snap) => (snap.get('fcmTokens') as string[] | undefined) ?? [],
    );
    if (tokens.length === 0) return;

    await msg.sendEachForMulticast({
      tokens,
      notification: {
        title: group.get('name') ?? '새 메시지',
        body: `${message.senderName}: ${message.text}`,
      },
      data: { groupId, type: 'chat' },
    });
  },
);
```

배포:

```bash
firebase use flutter-firebase-test-4b17c
firebase deploy --only functions
```

## 6단계: 테스트

- 실기기 2대(또는 1대 + 다른 기기) 필요 — iOS 시뮬레이터는 푸시 수신 제한.
- 계정 A가 채팅에 메시지 → 계정 B 기기에 푸시 도착 확인.
- 알림 권한 거부/허용 분기 확인.

## 한계 / 후속 권장

- 발송 실패(예: 토큰 만료) 응답 코드를 보고 `fcmTokens`에서 해당 토큰을
  자동 제거하는 정리 로직을 Cloud Function에 추가.
- 그룹 상태 변경(모집 종료/시작, 그룹 종료) 알림도 같은 패턴으로
  `onDocumentUpdated('group/{groupId}', …)` 트리거를 추가 가능.
- 멤버가 같은 디바이스에서 여러 기기 토큰을 보관하므로 `fcmTokens`는
  배열 유지가 적절.
