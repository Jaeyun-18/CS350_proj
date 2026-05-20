# WeBuyDivvy

WeBuyDivvy는 KAIST 학생만 사용할 수 있는 공동구매 분할 플랫폼입니다.
`@kaist.ac.kr` 이메일 인증을 기반으로 회원을 제한하고, 공동구매 그룹을 만들고 찾고 참여하고 관리하는 흐름을 제공하는 모바일 중심 Flutter 앱입니다.

이 저장소는 현재 **Flutter + Firebase** 기반으로 구성되어 있으며, 로그인/회원가입, 이메일 인증, 사용자 프로필 저장, 홈 피드(위치·품목 카테고리 필터 포함), 내 그룹 분리, 그룹 생성, 그룹 상세, 그룹 설정, 그룹 참여/나가기(동일 품목 카테고리 중복 참여 제한), 그룹별 실시간 채팅(참여/이탈 시스템 메시지 포함), 물품/분담 UI, My Page까지 연결되어 있습니다. FCM 푸시 알림은 클라이언트와 Cloud Functions 코드가 준비되어 있고 외부 인프라(APNs 키·Blaze 플랜·`firebase deploy`)만 남았습니다 — [PHASE6_FCM_HANDOFF.md](PHASE6_FCM_HANDOFF.md) 참고.

---

## 어떤 프로그램인가요?

WeBuyDivvy는 대용량 식료품이나 공동구매 상품을 여러 사람이 함께 나눠 사기 쉽게 만드는 서비스입니다.
혼자 구매하면 부담이 큰 상품을 KAIST 학생끼리 함께 구매하고, 나중에 비용과 수량을 나누는 것을 목표로 합니다.

핵심 아이디어는 다음과 같습니다.

- KAIST 학생만 가입할 수 있도록 이메일 도메인을 제한합니다.
- Firebase Auth로 로그인/회원가입/비밀번호 재설정을 처리합니다.
- 이메일 인증이 완료된 사용자만 메인 화면으로 들어갈 수 있습니다.
- Firestore에 사용자 프로필과 그룹 데이터를 저장합니다.
- 홈 피드는 참여 가능한 그룹만 보여주고, My Groups는 호스팅/참여 그룹을 분리합니다.
- 그룹 상세에서 참여 상태에 따라 액션이 달라지고, 호스트는 그룹 설정에서 모집 종료/재개와 그룹 종료를 관리합니다.

---

## 현재 구현된 기능

### 인증/계정 관리

- 이메일/비밀번호 로그인
- KAIST 도메인(`@kaist.ac.kr`)만 허용하는 회원가입
- 닉네임 중복 확인
- 선호 위치 선택
- 이메일 인증 링크 발송
- 비밀번호 재설정 메일 발송
- 로그인하지 않은 사용자는 인증 화면 외의 화면으로 들어갈 수 없음
- 이메일 인증이 완료되지 않은 사용자는 메인 화면으로 가지 못하고 인증 화면으로 이동

### 메인 화면

- Home 탭에서 참여 가능한 그룹만 표시
- 제일 상단에 마감이 임박했지만 아직 정원이 차지 않은 그룹을 강조
- **위치·품목 카테고리 다중 선택 필터** 바텀시트 — 활성 필터 개수가 홈 탭 필터 버튼에 배지로 표시
- 그룹 참여 시 Firestore 트랜잭션으로 `now_num`과 `member_ids`를 갱신
- **동일 품목 카테고리 그룹에는 동시에 한 곳에만 참여 가능** (참여 전 사전 검사)
- 모집 종료된 그룹은 비참여자의 홈에서 숨김
- My Groups 탭에서 호스팅 그룹과 참여 그룹을 분리 표시, 카드에서 채팅 바로가기 제공
- 그룹 상세 화면에서 상태에 따라 `참여`, `채팅`, `그룹 나가기`, `설정` 액션이 달라짐
- 그룹 설정 화면에서 정보 수정, 모집 종료/재개, 그룹 종료를 처리
- Create Group 화면에서 장소, 날짜, 시간, 최대 멤버 수, **공동구매 품목(이름·카테고리·수량)** 을 입력해 그룹 생성
- 그룹 상세의 **ITEMS 패널** — 멤버가 품목을 "내가 담당"으로 토글, 트랜잭션으로 동시 담당 충돌 방지
- 그룹별 실시간 채팅 (그룹 상세·My Groups 카드에서 진입, 멤버 전용)
- **참여/이탈 시 채팅방에 시스템 메시지 자동 기록** (가운데 정렬 회색 칩)
- **My Page** — 프로필(닉네임·이메일·인증 상태), 선호 위치 변경, 로그아웃
- FCM 토큰을 로그인 직후 `users/{uid}.fcmTokens`에 등록 (실제 발송은 Cloud Functions 배포 후)

### 실행 지원

- macOS 데스크톱 실행 가능
- Chrome 웹 실행 가능
- iOS 시뮬레이터 실행 가능
- Android 에뮬레이터 실행 가능
- iOS deployment target은 15.0으로 맞춤

---

## 화면 흐름

앱이 실행되면 다음 순서로 동작합니다.

1. Firebase 초기화
2. 로그인 상태 확인
3. 로그인하지 않은 경우
   - 로그인 화면
   - 회원가입 화면
   - 비밀번호 재설정 화면
4. 로그인은 했지만 이메일 인증이 안 된 경우
   - 이메일 인증 대기 화면
5. 이메일 인증이 완료된 경우
   - 메인 화면
   - Home 탭
   - My Groups 탭
   - Group Details 화면
   - Group Settings 화면
   - Create Group 진입

---

## 기술 스택

- Flutter / Dart
- Firebase Auth — 이메일/비밀번호 + KAIST 도메인 제한
- Cloud Firestore — 사용자·그룹·메시지 데이터, 보안 규칙(`firestore.rules`)
- Firebase Cloud Messaging (FCM) — 클라이언트 토큰 등록
- Cloud Functions (TypeScript, Node 20) — 새 채팅 메시지 시 FCM 발송 트리거(`functions/`)
- CocoaPods / iOS Simulator

---

## 프로젝트 구조

주요 파일은 아래와 같습니다.

- [lib/main.dart](/Users/jimin/CS/SE/proj/lib/main.dart)
  - Firebase 초기화와 앱 시작점
  - `AuthGate` 연결
- [lib/auth/auth_gate.dart](/Users/jimin/CS/SE/proj/lib/auth/auth_gate.dart)
  - 로그인 상태에 따라 화면 분기
- [lib/auth/login_page.dart](/Users/jimin/CS/SE/proj/lib/auth/login_page.dart)
  - 이메일/비밀번호 로그인 화면
- [lib/auth/signup_page.dart](/Users/jimin/CS/SE/proj/lib/auth/signup_page.dart)
  - 회원가입 화면
  - 닉네임 중복 확인
  - KAIST 이메일 제한
- [lib/auth/verify_email_page.dart](/Users/jimin/CS/SE/proj/lib/auth/verify_email_page.dart)
  - 이메일 인증 대기 화면
- [lib/auth/reset_password_page.dart](/Users/jimin/CS/SE/proj/lib/auth/reset_password_page.dart)
  - 비밀번호 재설정 화면
- [lib/auth/auth_service.dart](/Users/jimin/CS/SE/proj/lib/auth/auth_service.dart)
  - Firebase Auth / Firestore 연결 로직
- [lib/main_page.dart](/Users/jimin/CS/SE/proj/lib/main_page.dart)
  - 로그인 완료 후 메인 화면
- [lib/main_page_tabs.dart](/Users/jimin/CS/SE/proj/lib/main_page_tabs.dart)
  - Home 탭과 공용 카드 UI
- [lib/my_groups_page.dart](/Users/jimin/CS/SE/proj/lib/my_groups_page.dart)
  - My Groups 탭
- [lib/group_page.dart](/Users/jimin/CS/SE/proj/lib/group_page.dart)
  - 그룹 상세 화면
- [lib/group_settings_page.dart](lib/group_settings_page.dart)
  - 그룹 설정 화면 (품목 편집 포함)
- [lib/groupcreate.dart](lib/groupcreate.dart)
  - 그룹 생성 화면 (품목 입력 포함)
- [lib/group_items.dart](lib/group_items.dart)
  - 품목 데이터 모델(`GroupItem`, `kItemCategories`) + 담당 토글/저장 트랜잭션
- [lib/group_items_editor.dart](lib/group_items_editor.dart)
  - 그룹 생성·설정에서 공유하는 품목 편집 위젯 + 추가 다이얼로그
- [lib/group_filter.dart](lib/group_filter.dart)
  - 홈 피드 필터 모델(`GroupFilter`) + 위치·품목 카테고리 바텀시트
- [lib/chat_service.dart](lib/chat_service.dart)
  - 채팅 모델(`ChatMessage`) + Firestore 채팅 서비스 + 참여/이탈 시스템 메시지
- [lib/chat_page.dart](lib/chat_page.dart)
  - 그룹 채팅 UI (메시지 버블·시스템 칩·입력 바)
- [lib/messaging_service.dart](lib/messaging_service.dart)
  - FCM 권한 요청·토큰 등록/갱신/해제
- [functions/src/index.ts](functions/src/index.ts)
  - Cloud Function `onChatMessage` — 새 사용자 메시지 시 멤버들에게 FCM 발송
- [firestore.rules](firestore.rules)
  - Firestore 보안 규칙 (멤버 전용 채팅 읽기/쓰기 등)

---

## 데이터 구조

현재 Firebase에서 사용하는 주요 데이터는 다음과 같습니다.

### Firestore `users`

사용자 프로필은 `users/{uid}`에 저장됩니다.

예시 필드:

- `uid`
- `email`
- `displayName`
- `displayNameLower`
- `preferredLocation`
- `emailVerified`
- `registrationStatus`
- `fcmTokens` (string 배열) — FCM 푸시 알림 발송 대상 디바이스 토큰 목록, `arrayUnion`/`arrayRemove`로 병합/정리
- `createdAt`
- `updatedAt`

### 닉네임 예약 문서

닉네임 중복 방지를 위해 `users` 컬렉션 안에 예약용 문서를 함께 사용합니다.

예시:

- `users/__display_name_lock__jimin`

이 문서는 실제 사용자 프로필이 아니라, 특정 닉네임이 이미 점유되었음을 표시하는 내부 예약 문서입니다.

### Firestore `group`

메인 화면과 상세 화면에서는 `group` 컬렉션의 문서를 읽어 Home 탭, My Groups 탭, Group Details 화면을 구성합니다.

현재 예시 필드:

- `name`
- `location`
- `date_time`
- `max_num`
- `now_num`
- `user_id`
- `member_ids`
- `items` (배열) — 공동구매 품목 목록, 각 항목은 `{id, name, category, quantity, claimedBy}`. `id`로 안정적 식별, `category`는 `kItemCategories`(신선식품/냉장·냉동/가공식품/음료/생활용품/기타) 중 하나
- `status`
- `recruitment_status`
- `endedAt`
- `recruitmentClosedAt`
- `recruitmentOpenedAt`

상태 값 예시:

- `status: active`
- `status: ended`
- `recruitment_status: open`
- `recruitment_status: closed`

### Firestore `group/{groupId}/messages` (서브컬렉션)

그룹별 실시간 채팅 메시지가 저장됩니다. 멤버만 읽기/쓰기할 수 있도록 `firestore.rules`에 규칙이 적용되어 있습니다.

예시 필드:

- `text`
- `senderId`
- `senderName`
- `type` — `'user'`(일반 메시지) 또는 `'system'`(참여/이탈 안내)
- `createdAt` (server timestamp)

---

## 실행 전 준비 사항

로컬에서 실행하려면 아래가 필요합니다.

- macOS
- Xcode 설치
- iOS Simulator 사용 가능 상태
- Flutter SDK
- CocoaPods
- Firebase 프로젝트 연결

### 권장 확인 명령

```bash
flutter --version
xcodebuild -version
pod --version
flutter doctor
```

---

## 실행 방법

### 1. 의존성 설치

프로젝트 루트에서 Flutter 패키지를 설치합니다.

```bash
flutter pub get
```

### 2. CocoaPods 설치(필요한 경우)

이 단계는 iOS 시뮬레이터나 iPhone 실기기를 실행할 때 필요합니다.
macOS 데스크톱이나 Chrome 웹만 실행할 경우에는 건너뛰어도 됩니다.

```bash
brew install cocoapods
```

Pods가 꼬였거나 처음 iOS를 실행하는 경우:

```bash
cd ios
pod install
cd ..
```

### 3. 실행할 디바이스 확인

```bash
flutter devices
```

### 4. 플랫폼별 실행 방법

#### macOS 데스크톱에서 실행

```bash
flutter run -d macos
```

#### Chrome 웹에서 실행

```bash
flutter run -d chrome
```

#### iOS 시뮬레이터에서 실행

```bash
open -a Simulator
flutter devices
flutter run -d "iPhone 17"
```

시뮬레이터 이름이 다르면 `flutter devices`에 표시된 이름을 그대로 사용하면 됩니다.

#### Android 에뮬레이터에서 실행

```bash
flutter emulators
flutter emulators --launch <emulator_id>
flutter run -d <device_id>
```

#### 디바이스를 직접 지정하지 않고 실행

```bash
flutter run
```

---

## Firebase 설정

이 프로젝트는 Firebase 프로젝트에 연결되어 있습니다.

현재 설정은 [lib/firebase_options.dart](/Users/jimin/CS/SE/proj/lib/firebase_options.dart)에 들어 있으며, Firebase 프로젝트 ID는 `flutter-firebase-test-4b17c`입니다.

### 필요한 Firebase 기능

- Authentication
  - Email/Password 로그인 활성화
- Cloud Firestore
  - `users`
  - `group` (+ `group/{id}/messages` 서브컬렉션)
  - `firestore.rules` 배포 필요 (`firebase deploy --only firestore:rules`)
- Cloud Messaging (FCM)
  - APNs 키 업로드(Project settings → Cloud Messaging)
- Cloud Functions (TypeScript, Node 20)
  - `functions/src/index.ts`의 `onChatMessage` 트리거 배포
  - 결제 플랜을 **Blaze**로 업그레이드해야 외부 발신이 가능
  - 자세한 단계는 [PHASE6_FCM_HANDOFF.md](PHASE6_FCM_HANDOFF.md) 참고

### 다른 Firebase 프로젝트로 바꾸는 경우

```bash
flutterfire configure
```

그다음 `lib/firebase_options.dart`가 새 프로젝트 설정으로 갱신됩니다.

---

## 앱 동작 방식

### 회원가입

회원가입 화면에서는 다음 정보를 입력합니다.

- 이메일
- 닉네임
- 비밀번호
- 비밀번호 확인
- 선호 위치

추가 규칙:

- 이메일은 `@kaist.ac.kr`만 허용됩니다.
- 닉네임은 중복 확인 버튼을 눌러야 합니다.
- 가입 후 이메일 인증 링크를 받아 인증을 완료해야 합니다.

### 로그인

로그인은 이메일/비밀번호로 진행합니다.

- 로그인 성공 후 이메일이 인증되어 있으면 메인 화면으로 이동합니다.
- 로그인은 되었지만 이메일이 인증되지 않았으면 이메일 인증 화면으로 이동합니다.

### 비밀번호 재설정

비밀번호를 잊은 경우 KAIST 이메일로 재설정 메일을 보낼 수 있습니다.

### 메인 화면

메인 화면에서는 다음 정보를 보여줍니다.

- Home 탭의 참여 가능 그룹 목록 (위치·품목 카테고리 필터 적용, 활성 필터 개수 배지)
- 선호 위치
- My Groups 탭의 호스팅/참여 그룹 목록 (카드별 채팅 바로가기)
- Create Group 진입 버튼 (그룹 기본 정보 + 공동구매 품목 입력)
- My Page 탭 — 프로필, 선호 위치 변경, 로그아웃

### 그룹 상세 / 설정

- 가입 전에는 `참여` 또는 `모집 종료` 상태를 볼 수 있습니다.
- 가입 후에는 `채팅`과 `그룹 나가기`가 표시됩니다.
- ITEMS 패널에서 멤버가 공동구매 품목을 "내가 담당"으로 토글할 수 있습니다 (트랜잭션으로 동시 담당 충돌 방지).
- 호스트는 우측 상단 설정 버튼에서 그룹 정보와 품목 목록을 수정할 수 있습니다 (설정 저장은 트랜잭션으로 라이브 담당 상태를 보존).
- 호스트는 모집을 종료하거나 다시 시작할 수 있습니다.
- 호스트는 그룹을 종료할 수 있습니다.

### 그룹 채팅

- 그룹 상세의 `채팅` 버튼 또는 My Groups 카드의 채팅 아이콘으로 진입.
- `group/{id}/messages` 서브컬렉션을 `StreamBuilder`로 실시간 구독.
- 멤버가 참여/이탈하면 시스템 메시지(가운데 회색 칩)로 자동 기록.
- 빈 메시지 전송 차단, 로그아웃 시 FCM 토큰 자동 정리.

---

## 테스트 및 점검

코드 변경 후 아래 명령으로 기본 점검을 할 수 있습니다.

```bash
flutter analyze
flutter test
```

---

## 자주 만나는 문제

### 1. `CocoaPods not installed`

`pod` 명령이 없을 때 나타납니다.

해결:

```bash
brew install cocoapods
cd ios
pod install
cd ..
```

### 2. `No supported devices found`

iPhone 시뮬레이터가 아직 부팅되지 않았거나, Xcode에서 시뮬레이터가 등록되지 않았을 때 발생합니다.

해결:

```bash
open -a Simulator
flutter devices
```

### 3. `CocoaPods could not find compatible versions`

iOS deployment target이 너무 낮을 때 생길 수 있습니다.

이 프로젝트는 iOS 15.0 이상을 사용하도록 설정되어 있습니다.

### 4. 회원가입 후 `internal error`가 뜸

Firebase Auth 오류의 상세 원인은 Xcode 콘솔에 더 자세히 나올 수 있습니다.

이 경우 Xcode 콘솔 로그를 확인하면 원인 파악이 더 쉽습니다.

---

## 향후 확장 예정 기능

명세서 §2 기준 미완성 항목과 이후 확장 가능성이 있는 항목입니다.

- **FCM 푸시 알림** — 클라이언트와 Cloud Function 코드는 작성되어 있고, APNs 키 업로드·Blaze 플랜·`firebase deploy --only functions`만 남았습니다. [PHASE6_FCM_HANDOFF.md](PHASE6_FCM_HANDOFF.md) 참고.
- 그룹 상태 변경(모집 종료/시작, 그룹 종료) 푸시 알림 — `onDocumentUpdated` 트리거 추가로 확장 가능.
- 포그라운드 알림 배너 표시 — `flutter_local_notifications` 연동.
- 닉네임 수정 — `displayName` 잠금 문서 release/claim 트랜잭션 필요.

---

## 참고 문서

- [WeBuyDivvy_기능명세서.md](WeBuyDivvy_기능명세서.md) — 기능별 진행 상태와 수용 기준
- [PHASE6_FCM_HANDOFF.md](PHASE6_FCM_HANDOFF.md) — FCM 푸시 알림 외부 인프라 설정 5단계
