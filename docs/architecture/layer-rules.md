# Layer Rules — 레이어 의존성 규칙

## 이 문서의 목적

CLAUDE.md에 명시된 레이어 규칙의 **배경, 상세 설명, 경계 케이스**를 다룹니다.
핵심 규칙 자체는 CLAUDE.md를, 코드 예시는 `patterns.md`를 참조하세요.

---

## 왜 이 구조인가

이 프로젝트는 Clean Architecture의 3레이어 구조를 따릅니다.
목표는 하나입니다: **domain 레이어의 완전한 독립**.

- domain이 Flutter나 외부 패키지에 의존하지 않으므로, 순수 Dart 유닛 테스트만으로 비즈니스 로직을 검증할 수 있습니다.
- 서버 API가 바뀌어도 data 레이어의 Model/Mapper만 수정하면 되고, domain의 Entity는 영향받지 않습니다.
- UI 프레임워크를 교체하더라도 domain과 data는 그대로 재사용할 수 있습니다.

---

## 레이어 다이어그램

```
┌─────────────────────────────────┐
│         presentation            │
│   Screen, ViewModel, Widgets    │
│                                 │
│   ✅ import: domain             │
│   ❌ import: data               │
└──────────────┬──────────────────┘
               │ 의존
               ▼
┌─────────────────────────────────┐
│           domain                │
│   UseCase, Entity,              │
│   Repository 인터페이스          │
│                                 │
│   ❌ import: presentation       │
│   ❌ import: data               │
│   ❌ import: package:flutter    │
│   ❌ import: dart:ui            │
└─────────────────────────────────┘
               ▲ 의존
               │
┌─────────────────────────────────┐
│            data                 │
│   DataSource, Repository 구현체, │
│   Model(DTO), Mapper            │
│                                 │
│   ✅ import: domain             │
│   ❌ import: presentation       │
└─────────────────────────────────┘
```

핵심 방향: `presentation → domain ← data`

domain은 중심에서 아무것도 참조하지 않습니다. presentation과 data가 각각 domain을 바라봅니다.

---

## 레이어별 상세 역할

### presentation/

UI를 구성하고 사용자 인터랙션을 처리합니다.

| 구성 요소 | 역할 | 파일 네이밍 |
|---|---|---|
| Screen | 페이지 단위 Widget, 라우트 진입점 | `*_screen.dart` |
| ViewModel | 화면 상태 관리, **UseCase만 호출** (Repository 직접 호출 금지) | `*_view_model.dart` |
| Widgets | 재사용 가능한 UI 조각 | `*_widget.dart` 또는 의미 있는 이름 |

**허용하는 import:**
- `domain/` 내의 Entity, UseCase
- `lib/core/` (theme, constants, utils, router)
- `lib/shared/widgets/`
- `package:flutter`, `package:flutter_riverpod` 등 UI 패키지

**금지하는 import:**
- `data/` 내의 어떤 파일도 (DataSource, Repository 구현체, Model, Mapper)
- `domain/` 내의 Repository 인터페이스 (ViewModel은 UseCase만 호출)
- 다른 feature의 `presentation/`

> 코드 예시: `patterns.md` → Presentation 레이어 패턴

### domain/

비즈니스 로직의 핵심입니다. 외부 의존성이 없는 순수 Dart 코드만 존재합니다.

| 구성 요소 | 역할 | 파일 네이밍 |
|---|---|---|
| Entity | 비즈니스 모델 (앱 내부에서 사용하는 데이터 구조) | `*_entity.dart` |
| Repository (인터페이스) | 데이터 접근 계약 (abstract class) | `*_repository.dart` |
| UseCase | 단일 비즈니스 작업 단위 | `*_usecase.dart` |

**허용하는 import:**
- 같은 feature의 `domain/` 내 다른 파일
- `lib/core/utils/` 중 순수 Dart 유틸만 (Flutter 의존 없는 것)

**금지하는 import:**
- `package:flutter` (Flutter SDK 의존성 전체)
- `dart:ui`
- `presentation/` 내의 어떤 파일도
- `data/` 내의 어떤 파일도
- 다른 feature의 `domain/`

> 코드 예시: `patterns.md` → Domain 레이어 패턴

### data/

외부 데이터 소스(API, DB, 캐시)와 통신하고, 외부 데이터를 domain Entity로 변환합니다.

| 구성 요소 | 역할 | 파일 네이밍 |
|---|---|---|
| Model (DTO) | API 응답/요청 데이터 구조, JSON 직렬화 포함 | `*_model.dart` |
| DataSource | API 호출, 로컬 DB 접근 등 실제 I/O | `*_data_source.dart` |
| Repository (구현체) | domain의 Repository 인터페이스를 구현 | `*_repository_impl.dart` |
| Mapper | Model(DTO) ↔ Entity 변환 전담 | `*_mapper.dart` |

**허용하는 import:**
- `domain/` 내의 Entity, Repository 인터페이스
- `lib/core/network/` (api_client.dart)
- `lib/core/utils/`
- 외부 패키지 (dio, hive 등)

**금지하는 import:**
- `presentation/` 내의 어떤 파일도
- 다른 feature의 `data/`

> 코드 예시: `patterns.md` → Data 레이어 패턴

---

## Entity와 Model(DTO)의 분리 원칙

이 규칙은 자주 위반되므로 상세히 설명합니다.

### 왜 분리하는가

API 응답 구조와 앱 내부에서 사용하는 데이터 구조는 다른 생명주기를 갖습니다.

- API가 `snake_case`로 내려줘도 앱에서는 `camelCase`를 씁니다.
- API가 불필요한 필드를 20개 내려줘도 앱에서는 5개만 씁니다.
- API 응답 구조가 바뀌어도 Entity를 사용하는 presentation 코드는 영향받지 않아야 합니다.

### 파일 배치

| 역할 | 위치 | 예시 |
|---|---|---|
| Model (DTO) | `data/models/` | `card_model.dart` — fromJson/toJson 포함 |
| Mapper | `data/mappers/` | `card_mapper.dart` — CardModel → CardEntity 변환 |
| Entity | `domain/entities/` | `card_entity.dart` — 순수 비즈니스 모델, JSON 무관 |

### 핵심 금지 사항

- Entity에 `fromJson`/`toJson`을 넣지 마세요.
- Model을 presentation에서 직접 사용하지 마세요.
- Repository 구현체에서 Model을 그대로 반환하지 마세요. Mapper를 통해 Entity로 변환 후 반환합니다.
- Mapper에 비즈니스 로직(유효성 검증, 권한 판단 등)을 넣지 마세요. 순수한 데이터 변환만 합니다.

> 올바른/금지 코드 예시: `patterns.md` → Data 레이어 패턴 → Model, Mapper 섹션

---

## core/ 와 shared/ 의 위치

`lib/core/`와 `lib/shared/`는 특정 레이어에 속하지 않는 공용 코드입니다.

### core/

인프라 수준의 공용 코드입니다. 모든 레이어에서 참조할 수 있습니다.

| 폴더 | 주로 사용하는 레이어 | 비고 |
|---|---|---|
| `core/network/` | data | Dio 클라이언트, 인터셉터 |
| `core/theme/` | presentation | 테마, 간격 상수 |
| `core/constants/` | 모든 레이어 | 앱 전역 상수 |
| `core/error/` | domain, data | `Result<T>`, `AppFailure` |
| `core/utils/` | 모든 레이어 | Logger, Extensions |
| `core/router/` | presentation | GoRouter 설정 |
| `core/l10n/` | presentation | 다국어 ARB 파일 |

**주의:** domain에서 core/를 참조할 때는 Flutter 의존성이 없는 파일만 허용됩니다.
`core/error/`, `core/utils/`, `core/constants/`는 순수 Dart이므로 허용.
`core/theme/`, `core/router/`, `core/l10n/`은 Flutter 의존성이 있으므로 금지.

### shared/

feature 간 공유되는 presentation 수준 코드입니다.

- `shared/widgets/` — 2개 이상의 feature에서 사용하는 Widget
- `shared/providers/` — 앱 전역 상태 Provider

**규칙:** feature 간 직접 import가 필요하면, 해당 코드를 `shared/`로 올려야 합니다.

---

## 경계 케이스

### Q: UseCase가 여러 Repository를 조합해야 할 때?

같은 feature 내의 Repository 인터페이스를 여러 개 주입받는 것은 허용됩니다.
다른 feature의 Repository가 필요하면, 해당 인터페이스를 `shared/`로 올리거나 별도 공용 도메인 모듈로 분리합니다.

### Q: Entity가 다른 Entity를 참조해도 되나?

같은 feature 내에서는 허용됩니다. 다른 feature의 Entity를 참조해야 하면 `shared/`로 올립니다.

### Q: Mapper에서 비즈니스 로직을 넣어도 되나?

안 됩니다. Mapper는 순수한 데이터 변환만 합니다.
변환 과정에서 계산이나 판단이 필요하면 UseCase에서 처리하세요.

### Q: ViewModel에서 Repository를 직접 호출해도 되나?

**안 됩니다.** 단순 CRUD를 포함해 모든 데이터 접근은 반드시 UseCase를 거칩니다.
통일성을 위한 팀 규칙이며, 다음과 같은 이점이 있습니다:

- 나중에 비즈니스 규칙이 추가될 때 UseCase만 수정하면 됨 (ViewModel 변경 불필요)
- 테스트 시 UseCase만 Mock하면 되므로 ViewModel 테스트가 단순해짐
- 코드 리뷰 시 "이건 UseCase가 필요한가?"를 매번 판단하지 않아도 됨

> 올바른/금지 코드 예시: `patterns.md` → Presentation 레이어 패턴 → ViewModel 섹션