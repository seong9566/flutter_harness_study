# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Flutter 3.x + Dart3.x 기반의 TODO 앱입니다.
상태관리는 RivierPod,네트워크는 Dio, 라우팅은 GoRouter를 사용합니다.
Clean Architecture(Presentation → Application → Domain → Infrastructure) 레이어를 따릅니다.

## 절대 규칙

- 새로운 패키지 추가 금지. pubspec.yaml의 dependencies를 수정하지 마세요. 필요하면 사람에게 제안만 하세요.
- Raw HTTP 호출 금지. 모든 네트워크 요청은 lib/core/network/api_client.dart의 Dio 인스턴스를 통해서만 합니다.
- BuildContext를 비동기 갭 너머로 전달 금지. await 이후에 context를 사용하면 안 됩니다. if (!context.mounted) return; 가드를 반드시 넣으세요.
- print() 사용 금지. 디버깅 로그는 lib/core/utils/logger.dart의 AppLogger를 사용하세요.
- dynamic 타입 사용 금지. 항상 명시적 타입을 지정하세요.

## 아키텍처 규칙

레이어 의존성: Presentation → Application → Domain → Infrastructure (역방향 참조 금지)

- Presentation에서 Infrastructure를 직접 import하지 마세요.
- Domain 레이어에서 `package:flutter`, `dart:ui` import 금지.
- DTO(Infrastructure)와 Entity(Domain)는 반드시 별도 클래스로 분리.

> 상세 아키텍처 문서: `docs/architecture/layer-rules.md`
> 디렉토리 구조 가이드: `docs/architecture/directory-structure.md`
> 패턴 예시 모음: `docs/architecture/patterns.md`

## 디렉토리 규칙

새 기능은 `lib/features/{feature_name}/` 아래에 3개 하위 폴더로 만드세요:

- `presentation/` — Screen, ViewModel, Widgets
- `domain/` — UseCase, Repository 인터페이스, Entity
- `data/` — DataSource, Repository 구현체, Model(DTO), Mapper

레이어 의존성: presentation → domain ← data (domain은 아무것도 참조하지 않음)

- presentation에서 data를 직접 import 금지.
- domain 레이어에서 `package:flutter` import 금지.
- Model(DTO)과 Entity는 반드시 별도 클래스. 변환은 Mapper를 통해서만.
- feature 간 직접 import 금지. 공유할 코드는 `lib/shared/`로.

> 전체 디렉토리 구조: `docs/architecture/directory-structure.md`

## 상태관리 규칙 (Riverpod)

- `StateNotifier` 사용 금지. `@riverpod` 코드 생성 방식만 사용.
- State 클래스는 `freezed`로 생성. 수동 `copyWith` 금지.
- Provider 내부에서 `ref.read` 금지. `ref.watch` 또는 생성자 주입 사용.
- ViewModel은 `presentation/` 레이어에 위치.

> 올바른/금지 패턴 예시: `docs/architecture/riverpod-patterns.md`

## 코딩 컨벤션

- `part` / `part of`는 `.g.dart`, `.freezed.dart` 코드 생성 파일에만 사용.
- 매직 넘버 금지. `lib/core/constants/`에 상수로 정의.
- Widget 파일은 200줄 이하. 넘으면 하위 Widget으로 분리.
- `StatefulWidget` 대신 `ConsumerWidget` + Riverpod 사용.
- `build()` 안에 비즈니스 로직 금지. ViewModel 메서드를 호출만.
- 패딩/마진 하드코딩 금지. `lib/core/theme/app_spacing.dart` 상수 사용.

## 에러 처리

- Repository 메서드는 `Either<AppFailure, T>` 또는 sealed class `Result<T>` 반환.
- `try-catch` 사용 시 반드시 `AppLogger.error()`로 로깅.
- UI 에러 표시는 `lib/shared/widgets/error_view.dart` 사용.

> Dart 스타일 가이드 상세: `docs/conventions/dart-style.md`
> Widget 작성 패턴 예시: `docs/conventions/widget-patterns.md`

## 테스트 규칙

- 테스트 파일은 `test/` 아래에 소스와 동일한 경로 구조로 생성.
- domain/ 레이어는 반드시 유닛 테스트 작성.
- Mock은 `mocktail` 사용. `mockito` 사용 금지.
- 테스트 커버리지 90% 이상 유지. `make coverage`로 측정.
- 테스트 실행: `flutter test`

> 테스트 패턴 및 예시: `docs/conventions/testing-guide.md`

## Git 규칙 

- 커밋 메시지: `type(scope): 설명` 형식 사용
    - type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
    - scope: 관련 feature 또는 모듈명 (예: `fix(card): 카드 목록 정렬 오류 수정`)
- 생성 파일(`.g.dart`, `.freezed.dart`)은 커밋에 포함. `.gitignore`에 넣지 마세요.
- freezed/riverpod 관련 파일 수정 시 반드시 실행:
  `dart run build_runner build --delete-conflicting-outputs`

## 파일 권한

### 수정 금지 (사람에게 요청)
- `pubspec.yaml` — 패키지 추가/삭제는 사람에게 제안만
- `.env*`, `firebase_options.dart` — 환경 변수 및 Firebase 설정

### 수정 시 주의
- `lib/core/network/api_client.dart` — 변경 전 영향 범위 확인
- `lib/core/router/app_router.dart` — 라우트 추가 시 기존 패턴 준수
- `lib/core/theme/app_theme.dart` — 디자인 시스템 일관성 유지aasdasd
- `android/`, `ios/`, `web/` — 플랫폼 네이티브 설정

## 자주 하는 실수 (학습된 규칙)
이 섹션은 과거 실수에서 학습된 규칙입니다. 새로운 실수가 발견되면 여기에 추가됩니다.


## 참고 문서

- 아키텍처 상세: docs/architecture.md
- API 스펙 : docs/api-spec.yaml
- 디자인 시스템: docs/design-system.md
- 온보딩 가이드: docs/onboarding.md