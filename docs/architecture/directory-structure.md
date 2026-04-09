# Directory Structure — 디렉토리 구조 가이드

## 이 문서의 목적

CLAUDE.md에 명시된 디렉토리 규칙의 **전체 트리, 각 폴더 역할, 새 feature 생성 절차**를 다룹니다.
핵심 규칙 자체는 CLAUDE.md를 참조하세요.

---

## 전체 디렉토리 트리

```
lib/
├── main.dart                        # 앱 진입점
├── app.dart                         # MaterialApp / ProviderScope 설정
│
├── core/                            # 공용 인프라 (모든 feature에서 참조 가능)
│   ├── network/
│   │   ├── api_client.dart          # Dio 싱글턴 인스턴스
│   │   ├── api_endpoints.dart       # API 엔드포인트 상수
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── error_interceptor.dart
│   │
│   ├── router/
│   │   ├── app_router.dart          # GoRouter 설정
│   │   └── route_names.dart         # 라우트 이름 상수
│   │
│   ├── theme/
│   │   ├── app_theme.dart           # ThemeData 정의
│   │   ├── app_colors.dart          # 색상 상수
│   │   ├── app_typography.dart      # 텍스트 스타일
│   │   └── app_spacing.dart         # 패딩/마진 상수
│   │
│   ├── l10n/
│   │   ├── app_ko.arb               # 한국어
│   │   └── app_en.arb               # 영어
│   │
│   ├── constants/
│   │   ├── app_constants.dart       # 앱 전역 상수
│   │   └── storage_keys.dart        # 로컬 저장소 키
│   │
│   ├── error/
│   │   ├── app_failure.dart         # sealed class AppFailure
│   │   └── result.dart              # sealed class Result<T>
│   │
│   └── utils/
│       ├── logger.dart              # AppLogger
│       ├── date_utils.dart          # 날짜 포맷 헬퍼
│       └── extensions/
│           ├── string_ext.dart
│           └── context_ext.dart
│
├── features/                        # 기능별 모듈 (세로 슬라이스)
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── signup_screen.dart
│   │   │   ├── view_models/
│   │   │   │   ├── login_view_model.dart
│   │   │   │   └── login_view_model.g.dart
│   │   │   └── widgets/
│   │   │       └── login_form_widget.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart       # abstract class (인터페이스)
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       └── signup_usecase.dart
│   │   └── data/
│   │       ├── models/
│   │       │   └── user_model.dart            # fromJson/toJson 포함
│   │       ├── mappers/
│   │       │   └── user_mapper.dart           # UserModel → UserEntity
│   │       ├── datasources/
│   │       │   └── auth_data_source.dart      # API 호출
│   │       └── repositories/
│   │           └── auth_repository_impl.dart  # AuthRepository 구현체
│   │
│   ├── card/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   │
│   └── settings/
│       ├── presentation/
│       ├── domain/
│       └── data/
│
└── shared/                          # feature 간 공유 코드
    ├── widgets/
    │   ├── error_view.dart          # 공용 에러 표시 Widget
    │   ├── loading_view.dart        # 공용 로딩 Widget
    │   └── app_button.dart          # 공용 버튼
    └── providers/
        └── connectivity_provider.dart  # 네트워크 상태 등 공용 Provider
```

---

## 각 폴더의 역할

### core/

모든 feature에서 참조하는 인프라 코드입니다. feature에 종속되지 않습니다.

| 폴더 | 역할 | 주로 사용하는 레이어 |
|---|---|---|
| `network/` | Dio 클라이언트, 인터셉터, API 엔드포인트 | data |
| `router/` | GoRouter 설정, 라우트 이름 | presentation |
| `theme/` | 색상, 타이포, 간격 상수 | presentation |
| `l10n/` | 다국어 ARB 파일 | presentation |
| `constants/` | 앱 전역 상수, 저장소 키 | 모든 레이어 |
| `error/` | AppFailure, Result\<T\> sealed class | domain, data |
| `utils/` | Logger, 날짜 헬퍼, Extensions | 모든 레이어 |

**주의:** domain 레이어에서 core/를 참조할 때는 Flutter 의존성이 없는 파일만 사용할 수 있습니다.
`core/error/`, `core/utils/logger.dart`, `core/constants/`는 순수 Dart이므로 허용됩니다.
`core/theme/`, `core/router/`, `core/l10n/`은 Flutter 의존성이 있으므로 domain에서 금지됩니다.

### features/{feature_name}/

하나의 기능을 구성하는 3개 레이어입니다.

| 폴더 | 내용물 | 네이밍 규칙 |
|---|---|---|
| `presentation/screens/` | 페이지 단위 Widget | `*_screen.dart` |
| `presentation/view_models/` | Riverpod ViewModel | `*_view_model.dart` |
| `presentation/widgets/` | 재사용 UI 조각 | 의미 있는 이름 |
| `domain/entities/` | 비즈니스 모델 | `*_entity.dart` |
| `domain/repositories/` | Repository 인터페이스 (abstract class) | `*_repository.dart` |
| `domain/usecases/` | 단일 비즈니스 작업 | `*_usecase.dart` |
| `data/models/` | API 응답/요청 DTO | `*_model.dart` |
| `data/mappers/` | Model ↔ Entity 변환 | `*_mapper.dart` |
| `data/datasources/` | API 호출, 로컬 DB 접근 | `*_data_source.dart` |
| `data/repositories/` | Repository 구현체 | `*_repository_impl.dart` |

### shared/

feature 간 공유되는 presentation 수준 코드입니다.

- `shared/widgets/` — 2개 이상의 feature에서 사용하는 Widget
- `shared/providers/` — 앱 전역 상태 Provider (네트워크 연결 상태 등)

---

## 새 feature 생성 절차

`card`라는 새 feature를 추가한다고 가정합니다.

### 1단계: 디렉토리 생성

```
lib/features/card/
├── presentation/
│   ├── screens/
│   ├── view_models/
│   └── widgets/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── data/
    ├── models/
    ├── mappers/
    ├── datasources/
    └── repositories/
```

### 2단계: domain부터 작성 (안쪽 → 바깥쪽 순서)

1. `domain/entities/card_entity.dart` — 비즈니스 모델 정의
2. `domain/repositories/card_repository.dart` — Repository 인터페이스 정의
3. `domain/usecases/get_cards_usecase.dart` — UseCase 작성

### 3단계: data 작성

4. `data/models/card_model.dart` — API DTO 정의 (fromJson/toJson)
5. `data/mappers/card_mapper.dart` — CardModel → CardEntity 변환
6. `data/datasources/card_data_source.dart` — API 호출
7. `data/repositories/card_repository_impl.dart` — Repository 구현체

### 4단계: presentation 작성

8. `presentation/view_models/card_view_model.dart` — UseCase 호출, 상태 관리
9. `presentation/screens/card_list_screen.dart` — 화면 구성
10. `presentation/widgets/` — 필요한 하위 Widget

### 작성 순서의 이유

domain → data → presentation 순서로 작성하면:
- domain을 작성할 때 외부 의존성을 신경 쓰지 않아도 됩니다.
- data 작성 시 domain 인터페이스가 이미 정의되어 있으므로 구현에 집중할 수 있습니다.
- presentation 작성 시 UseCase가 준비되어 있으므로 바로 연결할 수 있습니다.

---

## feature 간 코드 공유 규칙

### 금지: feature 간 직접 import

```dart
// ❌ card feature에서 auth feature를 직접 import
import 'package:app/features/auth/domain/entities/user_entity.dart';
```

### 올바른: shared로 올린 후 import

```dart
// ✅ 공유가 필요한 Entity는 shared로 이동
import 'package:app/shared/entities/user_entity.dart';
```

### 판단 기준

- 1개 feature에서만 쓰는 코드 → 해당 feature 안에 유지
- 2개 이상 feature에서 쓰는 코드 → `shared/`로 이동
- feature와 무관한 인프라 코드 → `core/`에 위치