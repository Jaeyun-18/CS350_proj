# WeBuyDivvy

WeBuyDivvy는 KAIST 학생만 사용할 수 있는 공동구매 분할 플랫폼입니다.
`@kaist.ac.kr` 이메일 인증을 기반으로 회원을 제한하고, 공동구매 그룹을 만들고 찾고 참여하는 흐름을 제공하는 모바일 중심 Flutter 앱입니다.

이 저장소는 현재 **Flutter + Firebase** 기반으로 구성되어 있으며, 로그인과 회원가입, 이메일 인증, 사용자 프로필 저장, 그룹 목록 표시까지 연결되어 있습니다.

---

## 어떤 프로그램인가요?

WeBuyDivvy는 대용량 식료품이나 공동구매 상품을 여러 사람이 함께 나눠 사기 쉽게 만드는 서비스입니다.
혼자 구매하면 부담이 큰 상품을 KAIST 학생끼리 함께 구매하고, 나중에 비용과 수량을 나누는 것을 목표로 합니다.

핵심 아이디어는 다음과 같습니다.

- KAIST 학생만 가입할 수 있도록 이메일 도메인을 제한합니다.
- Firebase Auth로 로그인/회원가입/비밀번호 재설정을 처리합니다.
- 이메일 인증이 완료된 사용자만 메인 화면으로 들어갈 수 있습니다.
- Firestore에 사용자 프로필과 그룹 데이터를 저장합니다.
- 이후 기능 확장을 통해 그룹 매칭, 필터링, 참여, 채팅까지 이어지는 구조를 목표로 합니다.

---

## 현재 구현된 기능

현재 코드 기준으로 동작하는 기능은 다음과 같습니다.

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

- 로그인 후 사용자 프로필 표시
- Firestore `users/{uid}` 문서에서 `displayName`, `preferredLocation` 등을 읽음
- 선호 위치를 나중에 변경 가능
- Firestore `group` 컬렉션의 그룹 목록을 표시

### iOS 실행

- iOS 시뮬레이터에서 실행 가능하도록 CocoaPods 설정 완료
- iOS deployment target을 15.0으로 맞춤

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
   - 사용자 정보 표시
   - 그룹 목록 표시

---

## 기술 스택

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- CocoaPods
- iOS Simulator

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
- [lib/groupcreate.dart](/Users/jimin/CS/SE/proj/lib/groupcreate.dart)
  - 그룹 생성 관련 예시 화면

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
- `createdAt`
- `updatedAt`

### 닉네임 예약 문서

닉네임 중복 방지를 위해 `users` 컬렉션 안에 예약용 문서를 함께 사용합니다.

예시:

- `users/__display_name_lock__jimin`

이 문서는 실제 사용자 프로필이 아니라, 특정 닉네임이 이미 점유되었음을 표시하는 내부 예약 문서입니다.

### Firestore `group`

메인 화면에서는 `group` 컬렉션의 문서를 읽어 그룹 목록을 보여줍니다.

현재 예시 필드:

- `name`
- `location`
- `date_time`
- `max_num`

---

## 실행 전 준비 사항

로컬에서 iOS 시뮬레이터로 실행하려면 아래가 필요합니다.

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

### 2. iOS CocoaPods 설치(필요한 경우)

이 단계는 iOS 시뮬레이터나 iPhone 실기기를 실행할 때만 필요합니다.
macOS 데스크톱이나 Chrome 웹만 실행할 경우에는 건너뛰어도 됩니다.

처음 iOS를 실행하는 경우 또는 Pods 상태가 꼬였을 때 아래를 실행합니다.

```bash
cd ios
pod install
cd ..
```

만약 `pod` 명령이 없으면 먼저 CocoaPods를 설치해야 합니다.

```bash
brew install cocoapods
```

### 3. 실행할 디바이스 확인

현재 연결된 디바이스와 에뮬레이터를 확인합니다.

```bash
flutter devices
```

이 프로젝트는 iOS 시뮬레이터뿐 아니라 macOS 데스크톱과 Chrome 웹 브라우저에서도 실행할 수 있습니다.

### 4. 플랫폼별 실행 방법

#### macOS 데스크톱에서 실행

macOS로 바로 실행하려면 아래 명령을 사용합니다.

```bash
flutter run -d macos
```

#### Chrome 웹에서 실행

웹 브라우저에서 확인하려면 아래 명령을 사용합니다.

```bash
flutter run -d chrome
```

#### iOS 시뮬레이터에서 실행

Simulator 앱을 열고 iPhone 시뮬레이터를 부팅한 뒤 실행합니다.

```bash
open -a Simulator
```

필요하면 시뮬레이터 상태를 확인하고 직접 부팅할 수 있습니다.

```bash
xcrun simctl list devices available
xcrun simctl boot "iPhone 17"
```

그다음 실행합니다.

```bash
flutter run -d "iPhone 17"
```

기기 이름이 정확하지 않으면 `flutter devices`에 표시된 이름을 그대로 넣으면 됩니다.

#### Android 에뮬레이터에서 실행

Android SDK와 에뮬레이터가 설치되어 있다면 다음처럼 실행할 수 있습니다.

```bash
flutter emulators
flutter emulators --launch <emulator_id>
flutter run -d <device_id>
```

### 5. 가장 간단한 실행

디바이스를 따로 지정하지 않고 가능한 대상 하나로 실행하려면 아래처럼 해도 됩니다.

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
  - `group`

### 다른 Firebase 프로젝트로 바꾸는 경우

프로젝트를 새 Firebase 프로젝트에 연결하려면 FlutterFire CLI로 설정 파일을 다시 생성해야 합니다.

일반적인 흐름은 다음과 같습니다.

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

- 사용자 닉네임
- 이메일
- 이메일 인증 여부
- 선호 위치
- 그룹 목록

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

필요하면 Xcode에서 시뮬레이터 목록을 확인하고 다시 실행합니다.

### 3. `CocoaPods could not find compatible versions`

iOS deployment target이 너무 낮을 때 생길 수 있습니다.

이 프로젝트는 iOS 15.0 이상을 사용하도록 설정되어 있습니다.

### 4. 회원가입 후 `internal error`가 뜸

Firebase Auth 오류의 상세 원인은 Xcode 콘솔에 더 자세히 나올 수 있습니다.

이 경우 Xcode 콘솔 로그를 확인하면 원인 파악이 더 쉽습니다.

---

## 향후 확장 예정 기능

현재 명세서 기준으로 다음 기능은 이후 확장 대상입니다.

- 그룹 피드와 필터링
- 그룹 참여/나가기
- 내 그룹 목록
- 실시간 채팅
- 참여/이탈 시스템 메시지
- 푸시 알림

---

## 참고 문서

- [WeBuyDivvy_기능명세서.md](/Users/jimin/CS/SE/proj/WeBuyDivvy_%EA%B8%B0%EB%8A%A5%EB%AA%85%EC%84%B8%EC%84%9C.md)
