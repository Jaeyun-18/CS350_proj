# Phase 6 — FCM 푸시 알림 인프라 설정 안내

코드는 작성이 끝났고, 실제로 알림이 도착하려면 **외부 인프라(콘솔/CLI/배포)**
설정이 남았습니다. 아래 5단계를 끝내면 채팅 메시지가 푸시로 전달됩니다.

## 이미 작성된 코드

| 영역 | 파일 | 역할 |
|------|------|------|
| 클라이언트 | `lib/messaging_service.dart` | 알림 권한 요청 + 토큰 저장/갱신 |
| 클라이언트 | `lib/main_page.dart` (`_MainPageState.initState`) | 로그인 직후 `MessagingService.instance.registerForUser` 호출 |
| 서버 | `functions/src/index.ts` | 새 채팅 메시지 시 멤버들에게 FCM 발송, 무효 토큰 정리 |
| 설정 | `firebase.json` | `functions` 섹션 추가 |
| 의존성 | `pubspec.yaml` | `firebase_messaging: ^16.2.2` |

토큰 저장 위치: `users/{uid}.fcmTokens: string[]` (arrayUnion 병합).
알림 페이로드 data: `{groupId, type: "chat"}`.

## 1단계 — Apple Developer + Firebase Console

1. Apple Developer 콘솔에서 **APNs Auth Key(.p8)** 발급, Key ID·Team ID 메모.
2. Firebase Console → 프로젝트 `flutter-firebase-test-4b17c` →
   Project settings → **Cloud Messaging** → Apple app configuration에
   .p8 키 업로드.
3. 결제 플랜을 **Blaze(종량제)** 로 업그레이드 (Cloud Functions 외부 발신
   필수 조건).

## 2단계 — Xcode 권한

`ios/Runner.xcworkspace` 열고 Runner target → **Signing & Capabilities**에서:

- **Push Notifications** capability 추가
- **Background Modes** capability 추가 → "Remote notifications" 체크

## 3단계 — 네이티브 의존성 설치

```bash
flutter pub get
cd ios && pod install && cd ..
```

## 4단계 — Cloud Functions 배포

```bash
cd functions
npm install
cd ..
firebase use flutter-firebase-test-4b17c
firebase deploy --only functions
```

(첫 배포 시 Firebase Console에서 Cloud Functions·Cloud Build·Artifact Registry
API 사용 허용을 한 번 클릭해야 할 수 있습니다.)

## 5단계 — 실기기 테스트

- 실기기 2대(또는 1대 + 다른 기기) 필요 — iOS 시뮬레이터는 푸시 수신 제한.
- 계정 A가 그룹 채팅에 메시지 전송 → 계정 B 기기에 푸시 도착 확인.
- 알림 권한 거부/허용 분기, 앱 포그라운드/백그라운드 모두 확인.
- 로그 확인:
  ```bash
  firebase functions:log --only onChatMessage
  ```

## 알려진 한계 / 후속 권장

- **그룹 상태 변경 알림**(모집 종료/시작, 그룹 종료)은 현재 미발송 —
  같은 패턴으로 `onDocumentUpdated('group/{groupId}', …)` 트리거를 추가하면 됩니다.
- **포그라운드 알림 표시**: 현재 클라이언트는 토큰만 등록하므로 앱이 켜져
  있을 때는 OS가 자동으로 배너를 띄우지 않습니다. 필요하면
  `flutter_local_notifications`를 붙여 `FirebaseMessaging.onMessage` 핸들러에서
  배너를 표시하세요.
- **무효 토큰 정리**는 서버에서 발송 실패 응답(`messaging/registration-
  token-not-registered`, `messaging/invalid-registration-token`)을 기준으로
  자동 제거하도록 이미 구현되어 있습니다.
