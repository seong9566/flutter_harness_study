---
name: architecture
description: >
  Flutter Clean Architecture 프로젝트의 구조 설계, feature 구현, 아키텍처 리뷰를 위한
  규칙 레퍼런스입니다. 이 프로젝트의 레이어 의존성, Riverpod 패턴, 에러 처리, 파일 구조 규칙을
  항상 참조하여 코드를 작성하거나 검토합니다.

  다음 상황에서 반드시 이 스킬을 참조하세요:
  - feature 구현 요청 ("카드 기능 만들어줘", "로그인 화면 추가해줘")
  - 레이어 경계 관련 질문 ("이 import 맞아?", "ViewModel에서 이거 써도 돼?")
  - Entity/Repository/UseCase/ViewModel/Screen 작성 시
  - 아키텍처 리뷰 ("이 코드 구조 맞는지 확인해줘")
  - 에러 처리, 상태관리 패턴 선택 시
  - 새 파일 위치/네이밍 결정 시
---

# architecture 스킬

이 프로젝트는 Flutter 3.x + Dart 3.x 기반 Clean Architecture입니다.
아래 규칙을 코드 작성과 리뷰의 기준으로 삼습니다.

---

## 레이어 구조 (의존성 방향)

```
presentation → domain ← data
```

- **presentation**: Screen, ViewModel, Widgets — Flutter UI
- **domain**: Entity, Repository 인터페이스, UseCase — 순수 Dart
- **data**: Model(DTO), Mapper, DataSource, Repository 구현체

**핵심 금지사항:**
- presentation에서 data 레이어 직접 import 금지
- domain에서 `package:flutter` 또는 `dart:ui` import 금지
- feature 간 직접 import 금지 → 공유가 필요하면 `lib/shared/`로

---

## 레이어별 책임

### domain
- **Entity**: `@freezed`, JSON 직렬화 없음, 순수 비즈니스 모델
- **Repository 인터페이스**: `abstract class`, `Result<T>` 반환
- **UseCase**: Repository 인터페이스에만 의존, 단일 책임 (`call()`)

### data
- **Model(DTO)**: `@freezed` + `fromJson/toJson`, Dart 필드는 camelCase, 서버 snake_case는 `@JsonKey(name: '...')` 매핑
- **Mapper**: 순수 데이터 변환 (`static toEntity / toModel`), 비즈니스 로직 금지
- **DataSource**: Dio 호출만, Model 반환, `Result`로 감싸지 않음, 예외는 그냥 throw
- **Repository 구현체**: DataSource 호출 → Mapper 변환 → `Result<T>` 반환, try-catch에서 `AppLogger.error()` 사용

### presentation
- **ViewModel**: `@riverpod` 코드 생성 방식, UseCase만 호출 (Repository 직접 호출 금지)
- **State**: `@freezed`, 수동 `copyWith` 금지
- **Screen/Widget**: `ConsumerWidget`, `AsyncValue.when` 패턴, `build()`에 비즈니스 로직 금지
- **파일 크기**: Widget 파일 200줄 이하

---

## Riverpod 핵심 패턴

```dart
// ✅ build()에서 ref.watch, 메서드에서 ref.read
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    final useCase = ref.watch(getCardsUseCaseProvider); // watch
    final result = await useCase();
    return switch (result) {
      Success(:final data) => CardListState(cards: data),
      Failure(:final failure) => CardListState.error(failure),
    };
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final useCase = ref.read(getCardsUseCaseProvider); // read (메서드 내)
    ...
  }
}
```

**DI 체인**: `ViewModel → UseCaseProvider → RepositoryProvider → DataSourceProvider → dioProvider`

```dart
@riverpod
GetCardsUseCase getCardsUseCase(Ref ref) =>
    GetCardsUseCase(ref.watch(cardRepositoryProvider));

@riverpod
CardRepository cardRepository(Ref ref) =>
    CardRepositoryImpl(ref.watch(cardDataSourceProvider));

@riverpod
CardDataSource cardDataSource(Ref ref) =>
    CardDataSource(ref.watch(dioProvider));
```

---

## 에러 처리 패턴

```dart
// Repository 구현체
Future<Result<List<CardEntity>>> getCards() async {
  try {
    final models = await _dataSource.fetchCards();
    return Success(models.map(CardMapper.toEntity).toList());
  } catch (e) {
    AppLogger.error('카드 목록 조회 실패', error: e);
    return Failure(AppFailure.server(e.toString()));
  }
}

// ViewModel에서 exhaustive switch
return switch (result) {
  Success(:final data) => CardListState(cards: data),
  Failure(:final failure) => CardListState.error(failure),
};
```

---

## 절대 금지 규칙

| 금지 | 대체 |
|------|------|
| `print()` | `AppLogger.error/info/debug()` |
| `dynamic` 타입 | 명시적 타입 |
| `StateNotifier` | `@riverpod` 코드 생성 |
| Entity에 `fromJson` | data 레이어 Model에서만 |
| Model에 snake_case 필드 | camelCase + `@JsonKey` |
| `build()` 안에서 `ref.read` | `ref.watch` 사용 |
| `await` 후 `context.` (mounted 체크 없이) | `if (!context.mounted) return;` |
| 수동 `copyWith` | `@freezed` |
| `StatefulWidget` | `ConsumerWidget` + Riverpod |
| ViewModel에서 Repository 직접 참조 | UseCase를 거칠 것 |

---

## 파일 네이밍 & 경로

```
lib/features/{name}/
├── domain/
│   ├── entities/{name}_entity.dart
│   ├── repositories/{name}_repository.dart
│   └── usecases/{action}_{name}_usecase.dart
├── data/
│   ├── models/{name}_model.dart
│   ├── mappers/{name}_mapper.dart
│   ├── datasources/{name}_data_source.dart
│   ├── repositories/{name}_repository_impl.dart
│   └── {name}_providers.dart
└── presentation/
    ├── screens/{name}_list_screen.dart
    ├── view_models/{name}_list_view_model.dart
    └── widgets/
```

---

## 상세 패턴 참조

더 자세한 코드 예시가 필요하면:
- **레이어 의존성 규칙 + 경계 케이스** → `docs/architecture/layer-rules.md`
- **레이어별 올바른/금지 코드 패턴** → `docs/architecture/patterns.md`
- **Riverpod autoDispose/keepAlive/family 패턴** → `docs/architecture/riverpod-patterns.md`
- **전체 디렉토리 트리 + feature 생성 절차** → `docs/architecture/directory-structure.md`
- **에러 처리 상세** → `docs/architecture/error-handling.md`
