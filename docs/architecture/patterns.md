# Patterns — 레이어별 코드 패턴 모음

## 이 문서의 목적

CLAUDE.md와 `layer-rules.md`에 명시된 규칙의 **구체적인 코드 예시**를 다룹니다.
각 레이어에서 올바른 패턴과 금지 패턴을 나란히 보여줍니다.

---

## Domain 레이어 패턴

### Entity

```dart
// ✅ freezed로 정의, 순수 Dart만 사용
@freezed
class CardEntity with _$CardEntity {
  const factory CardEntity({
    required String id,
    required String title,
    required String description,
    required DateTime createdAt,
    required bool isCompleted,
  }) = _CardEntity;
}
```

```dart
// ❌ Entity에 fromJson/toJson을 넣는 것
@freezed
class CardEntity with _$CardEntity {
  const factory CardEntity({...}) = _CardEntity;

factory CardEntity.fromJson(Map<String, dynamic> json) =>
_$CardEntityFromJson(json);  // ❌ JSON 직렬화는 data 레이어의 Model에서
}
```

```dart
// ❌ Entity에서 Flutter 의존성 사용
import 'package:flutter/material.dart';  // ❌

class CardEntity {
  final Color statusColor;  // ❌ UI 관심사는 presentation에서
}
```

### Repository 인터페이스

```dart
// ✅ abstract class, Result<T> 반환
abstract class CardRepository {
  Future<Result<List<CardEntity>>> getCards();
  Future<Result<CardEntity>> getCardById(String id);
  Future<Result<void>> createCard(CardEntity card);
  Future<Result<void>> updateCard(CardEntity card);
  Future<Result<void>> deleteCard(String id);
}
```

```dart
// ❌ Repository 인터페이스에서 Model(DTO)을 반환
abstract class CardRepository {
  Future<CardModel> getCards();  // ❌ Entity를 반환해야 함
}
```

```dart
// ❌ Repository 인터페이스에서 Dio 타입을 노출
import 'package:dio/dio.dart';  // ❌ domain에서 외부 패키지 의존

abstract class CardRepository {
  Future<Response> getCards();  // ❌
}
```

### UseCase

```dart
// ✅ 단일 책임, Repository 인터페이스에 의존
class GetCardsUseCase {
  final CardRepository _repository;

  GetCardsUseCase(this._repository);

  Future<Result<List<CardEntity>>> call() {
    return _repository.getCards();
  }
}
```

```dart
// ✅ 비즈니스 로직이 포함된 UseCase
class CompleteCardUseCase {
  final CardRepository _repository;

  CompleteCardUseCase(this._repository);

  Future<Result<void>> call(String cardId) async {
    final result = await _repository.getCardById(cardId);

    return switch (result) {
      Success(:final data) => data.isCompleted
          ? Failure(AppFailure.validation('이미 완료된 카드입니다'))
          : _repository.updateCard(data.copyWith(isCompleted: true)),
      Failure() => result,
    };
  }
}
```

```dart
// ❌ UseCase에서 DataSource를 직접 참조
class GetCardsUseCase {
  final CardDataSource _dataSource;  // ❌ Repository를 거쳐야 함

  Future<List<CardModel>> call() {
    return _dataSource.fetchCards();  // ❌ Model이 아니라 Entity를 반환해야 함
  }
}
```

---

## Data 레이어 패턴

### Model (DTO)

```dart
// ✅ Dart 필드는 camelCase, 서버 snake_case는 @JsonKey로 매핑
@freezed
class CardModel with _$CardModel {
  const factory CardModel({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'created_at') required String createdAt,
    required bool isCompleted,
    @JsonKey(name: 'author_name') required String authorName,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _CardModel;

  factory CardModel.fromJson(Map<String, dynamic> json) =>
      _$CardModelFromJson(json);
}
```

```dart
// ❌ Dart 필드에 snake_case 사용
@freezed
class CardModel with _$CardModel {
  const factory CardModel({
    required String created_at,     // ❌ createdAt + @JsonKey
    required int is_completed,      // ❌ isCompleted + @JsonKey
  }) = _CardModel;
}
```

```dart
// ❌ Model에서 비즈니스 변환을 하는 것
class CardModel {
  DateTime get parsedCreatedAt => DateTime.parse(createdAt);  // ❌ Mapper에서 할 일
}
```

### Mapper

```dart
// ✅ 순수한 데이터 변환만 담당
class CardMapper {
  static CardEntity toEntity(CardModel model) {
    return CardEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      createdAt: DateTime.parse(model.createdAt),
      isCompleted: model.isCompleted,
    );
  }

  static CardModel toModel(CardEntity entity) {
    return CardModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt.toIso8601String(),
      isCompleted: entity.isCompleted,
      authorName: '',
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
```

```dart
// ❌ Mapper에 비즈니스 로직을 넣는 것
class CardMapper {
  static CardEntity toEntity(CardModel model) {
    return CardEntity(
      // ❌ 유효성 검증은 UseCase에서
      title: model.title.isEmpty ? '제목 없음' : model.title,
      // ❌ 권한 판단은 UseCase에서
      isEditable: model.authorName == currentUser,
    );
  }
}
```

### DataSource

```dart
// ✅ API 호출만 담당, Model 반환
class CardDataSource {
  final Dio _client;

  CardDataSource(this._client);

  Future<List<CardModel>> fetchCards() async {
    final response = await _client.get(ApiEndpoints.cards);
    final list = response.data['data'] as List;
    return list.map((json) => CardModel.fromJson(json)).toList();
  }

  Future<CardModel> fetchCardById(String id) async {
    final response = await _client.get('${ApiEndpoints.cards}/$id');
    return CardModel.fromJson(response.data['data']);
  }

  Future<void> createCard(CardModel model) async {
    await _client.post(ApiEndpoints.cards, data: model.toJson());
  }
}
```

```dart
// ❌ DataSource에서 Entity를 반환
class CardDataSource {
  Future<CardEntity> fetchCards() async {  // ❌ Model을 반환해야 함
    final response = await _client.get(ApiEndpoints.cards);
    return CardEntity(...);  // ❌ 변환은 Repository/Mapper에서
  }
}
```

```dart
// ❌ DataSource에서 에러를 가공
class CardDataSource {
  Future<Result<List<CardModel>>> fetchCards() async {  // ❌ Result는 Repository에서
    try {
    ...
    return Success(models);  // ❌
    } catch (e) {
    return Failure(...);     // ❌
    }
  }
}
```

### Repository 구현체

```dart
// ✅ DataSource 호출 → Mapper 변환 → Result 반환
class CardRepositoryImpl implements CardRepository {
  final CardDataSource _dataSource;

  CardRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<CardEntity>>> getCards() async {
    try {
      final models = await _dataSource.fetchCards();
      final entities = models.map(CardMapper.toEntity).toList();
      return Success(entities);
    } catch (e) {
      AppLogger.error('카드 목록 조회 실패', error: e);
      return Failure(AppFailure.server(e.toString()));
    }
  }

  @override
  Future<Result<void>> createCard(CardEntity card) async {
    try {
      final model = CardMapper.toModel(card);
      await _dataSource.createCard(model);
      return const Success(null);
    } catch (e) {
      AppLogger.error('카드 생성 실패', error: e);
      return Failure(AppFailure.server(e.toString()));
    }
  }
}
```

```dart
// ❌ Repository에서 Dio를 직접 호출
class CardRepositoryImpl implements CardRepository {
  final Dio _dio;  // ❌ DataSource를 거쳐야 함

  @override
  Future<Result<List<CardEntity>>> getCards() async {
    final response = await _dio.get('/cards');  // ❌
  }
}
```

---

## Presentation 레이어 패턴

### ViewModel

```dart
// ✅ UseCase만 호출, Result를 switch로 처리
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    final getCards = ref.watch(getCardsUseCaseProvider);
    final result = await getCards();

    return switch (result) {
      Success(:final data) => CardListState(cards: data),
      Failure(:final failure) => CardListState.error(failure),
    };
  }

  Future<void> deleteCard(String id) async {
    state = const AsyncValue.loading();
    final deleteCard = ref.read(deleteCardUseCaseProvider);
    final result = await deleteCard(id);

    switch (result) {
      case Success():
        ref.invalidateSelf();  // 목록 새로고침
      case Failure(:final failure):
        state = AsyncValue.error(failure, StackTrace.current);
    }
  }
}
```

```dart
// ❌ ViewModel에서 Repository 직접 호출
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    final repo = ref.watch(cardRepositoryProvider);  // ❌
    final cards = await repo.getCards();              // ❌ UseCase를 거쳐야 함
    return CardListState(cards: cards);
  }
}
```

```dart
// ❌ ViewModel에서 ref.read 사용
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    final getCards = ref.read(getCardsUseCaseProvider);  // ❌ ref.watch 사용
    ...
  }
}
```

### State

```dart
// ✅ freezed로 상태 정의
@freezed
class CardListState with _$CardListState {
  const factory CardListState({
    @Default([]) List<CardEntity> cards,
    @Default(false) bool isDeleting,
  }) = _CardListState;

  const factory CardListState.error(AppFailure failure) = _CardListStateError;
}
```

```dart
// ❌ 수동으로 copyWith 작성
class CardListState {
  final List<CardEntity> cards;

  CardListState copyWith({List<CardEntity>? cards}) {  // ❌ freezed 사용
    return CardListState(cards: cards ?? this.cards);
  }
}
```

### Screen / Widget

```dart
// ✅ ViewModel의 상태만 읽고, 메서드만 호출
class CardListScreen extends ConsumerWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardListViewModelProvider);

    return state.when(
      data: (cardState) => ListView.builder(
        itemCount: cardState.cards.length,
        itemBuilder: (context, index) => CardItemWidget(
          card: cardState.cards[index],
          onDelete: () => ref
              .read(cardListViewModelProvider.notifier)
              .deleteCard(cardState.cards[index].id),
        ),
      ),
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(error: error),
    );
  }
}
```

```dart
// ❌ Widget 안에서 비즈니스 로직 작성
class CardListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardListViewModelProvider);

    // ❌ 필터링 로직은 ViewModel이나 UseCase에서
    final activeCards = cards.where((c) => !c.isCompleted).toList();

    // ❌ 정렬 로직은 ViewModel이나 UseCase에서
    activeCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(...);
  }
}
```

```dart
// ❌ build() 안에서 비동기 작업 직접 실행
class CardListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ❌ build 안에서 API 호출
    final response = await ref.read(dioProvider).get('/cards');
    ...
  }
}
```

---

## 데이터 흐름 전체 패턴

```
사용자 탭 → Screen (onTap)
  → ViewModel.deleteCard(id)
    → DeleteCardUseCase.call(id)
      → CardRepository.deleteCard(id)       [인터페이스]
        → CardRepositoryImpl.deleteCard(id)  [구현체]
          → CardDataSource.deleteCard(id)    [API 호출]
            → Dio.delete('/cards/$id')

응답 ←
  ← DataSource: void (성공) 또는 throw (실패)
    ← RepositoryImpl: Result<void> (Success 또는 Failure로 감싸기)
      ← UseCase: Result<void> (그대로 전달 또는 추가 로직)
        ← ViewModel: state 업데이트 (switch로 분기)
          ← Screen: UI 자동 리빌드 (ref.watch)
```