# Onboarding — 프로젝트 셋업 가이드

## 이 문서의 목적
프로젝트를 처음 접할 때 필요한 **환경 구성, 실행 방법, 주요 명령어**를 다룹니다.
프로젝트 규칙은 CLAUDE.md를, 아키텍처는 `docs/architecture/`를 참조하세요.

---

## 기술 스택

| 영역 | 도구 |
|---|---|
| 프레임워크 | Flutter 3.x / Dart 3.x |
| 상태관리 | Riverpod (코드 생성 방식) |
| 네트워크 | Dio |
| 라우팅 | GoRouter |
| 데이터 모델 | freezed + json_serializable |
| 에러 처리 | sealed class `Result<T>` |
| 테스트 Mock | mocktail |
| 로컬 DB | sqlite |

---

## 환경 구성

### 1. Flutter SDK 확인

```bash
flutter --version
# Flutter 3.x / Dart 3.x 이상 필요

flutter doctor
# 모든 항목 ✅ 확인
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 코드 생성

freezed, riverpod, json_serializable 생성 파일을 빌드합니다.

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. 환경 변수

`.env` 파일이 프로젝트 루트에 필요합니다. `.env.example`을 복사해서 생성하세요.

```bash
cp .env.example .env
```

필수 환경 변수:

| 변수 | 설명 |
|---|---|
| `API_BASE_URL` | 백엔드 API 주소 |
| `API_KEY` | API 인증 키 |

> ⚠️ `.env` 파일은 Git에 포함되지 않습니다. 값은 팀 내부에서 공유합니다.

---

## 실행

### 개발 모드

```bash
# 디버그 모드 실행
flutter run

# 특정 기기 지정
flutter run -d chrome
flutter run -d ios
flutter run -d android
```

### 빌드

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 주요 명령어

### Makefile

| 명령어 | 동작 |
|---|---|
| `make test` | 전체 테스트 실행 |
| `make coverage` | 커버리지 측정 + HTML 리포트 + 90% 게이트 |
| `make coverage-all` | 미테스트 파일 포함한 정확한 커버리지 (CI용) |
| `make coverage-open` | 커버리지 HTML을 브라우저에서 열기 |
| `make analyze` | 정적 분석 (`flutter analyze`) |
| `make check` | analyze + coverage-all 한번에 (PR 전 점검) |
| `make clean` | 커버리지 산출물 정리 |

### 자주 쓰는 Flutter 명령어

```bash
# 정적 분석
flutter analyze

# 테스트
flutter test

# 코드 생성 (freezed, riverpod 변경 후)
dart run build_runner build --delete-conflicting-outputs

# 코드 생성 (watch 모드 — 개발 중 자동 재생성)
dart run build_runner watch --delete-conflicting-outputs

# 코드 포맷
dart format .
```

---

## 프로젝트 진입점

| 파일 | 역할 |
|---|---|
| `lib/main.dart` | 앱 진입점, 환경 변수 로드 |
| `lib/app.dart` | MaterialApp, ProviderScope, GoRouter 설정 |
| `lib/core/router/app_router.dart` | 라우트 정의 |
| `lib/core/network/api_client.dart` | Dio 싱글턴, 인터셉터 설정 |
| `lib/core/error/result.dart` | sealed class `Result<T>` 정의 |
| `lib/core/error/app_failure.dart` | sealed class `AppFailure` 정의 |

---

## 새 feature 작업 시작 체크리스트

1. `main`에서 feature 브랜치 생성: `feature/{scope}/{설명}`
2. `lib/features/{name}/` 아래에 3개 폴더 생성: `presentation/`, `domain/`, `data/`
3. domain → data → presentation 순서로 구현
4. `dart run build_runner build --delete-conflicting-outputs` 실행
5. `make check` 통과 확인
6. PR 생성

> 상세 절차: `docs/architecture/directory-structure.md` → 새 feature 생성 절차

---

## 문서 구조

```
docs/
├── architecture/
│   ├── layer-rules.md              # 레이어 의존성 규칙
│   ├── directory-structure.md      # 디렉토리 구조 가이드
│   ├── patterns.md                 # 레이어별 코드 패턴
│   ├── riverpod-patterns.md        # Riverpod 패턴 가이드
│   └── design-system.md            # 디자인 시스템
│
├── conventions/
│   ├── dart-style.md               # Dart 스타일 가이드
│   ├── widget-patterns.md          # Widget 작성 패턴
│   ├── testing-guide.md            # 테스트 패턴
│   └── git-conventions.md          # Git 컨벤션
│
└── onboarding.md                   # 이 문서
```