# Riverpod Patterns — Riverpod 패턴 가이드

## 이 문서의 목적

CLAUDE.md에 명시된 Riverpod 규칙의 **상세 패턴, 생명주기 관리, Provider 구성 방법**을 다룹니다.
레이어 간 데이터 흐름은 `patterns.md`를 참조하세요.

---

## Provider 선언 규칙

### 코드 생성 방식만 사용

```dart
// ✅ @riverpod 어노테이션 사용
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    ...
  }
}
```

```dart
// ❌ 수동 Provider 선언
final cardListProvider = StateNotifierProvider<CardListNotifier, CardListState>(
  (ref) => CardListNotifier(),
);
```

```dart
// ❌ StateNotifier 사용
class CardListNotifier extends StateNotifier<CardListState> {
  CardListNotifier() : super(const CardListState());
}
```

---

## autoDispose vs keepAlive

`@riverpod`은 기본적으로 autoDispose입니다. 화면을 벗어나면 Provider가 자동 해제됩니다.

### autoDispose (기본값) — 대부분의 경우

```dart
// ✅ 화면 전용 상태는 autoDispose 그대로 사용
@riverpod
class CardDetailViewModel extends _$CardDetailViewModel {
  @override
  FutureOr<CardDetailState> build(String cardId) async {
    final getCard = ref.watch(getCardUseCaseProvider);
    final result = await getCard(cardId);
    return switch (result) {
      Success(:final data) => CardDetailState(card: data),
      Failure(:final failure) => CardDetailState.error(failure),
    };
  }
}
```

### keepAlive — 앱 전역 상태

```dart
// ✅ 로그인 상태처럼 앱 전체에서 유지해야 하는 경우
@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  @override
  FutureOr<AuthState> build() async {
    final checkAuth = ref.watch(checkAuthUseCaseProvider);
    final result = await checkAuth();
    return switch (result) {
      Success(:final data) => AuthState.authenticated(data),
      Failure() => const AuthState.unauthenticated(),
    };
  }
}
```

### 판단 기준

| 상황 | 선택 | 이유 |
|---|---|---|
| 특정 화면의 상태 | autoDispose (기본) | 화면 벗어나면 메모리 해제 |
| 인증/사용자 정보 | keepAlive | 앱 전체에서 유지 필요 |
| 설정/테마 | keepAlive | 앱 전체에서 유지 필요 |
| 캐시 목적 | keepAlive | 재진입 시 API 재호출 방지 |

---

## ref.watch vs ref.read

### build() 안에서: ref.watch

```dart
// ✅ build()에서는 ref.watch — 의존성 변경 시 자동 리빌드
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    final getCards = ref.watch(getCardsUseCaseProvider);  // ✅ watch
    final result = await getCards();
    ...
  }
}
```

### 메서드 안에서: ref.read

```dart
// ✅ 이벤트 핸들러(메서드)에서는 ref.read — 일회성 호출
Future<void> deleteCard(String id) async {
  final deleteCard = ref.read(deleteCardUseCaseProvider);  // ✅ read
  final result = await deleteCard(id);
  ...
}
```

### 금지 패턴

```dart
// ❌ build()에서 ref.read 사용
@override
FutureOr<CardListState> build() async {
  final getCards = ref.read(getCardsUseCaseProvider);  // ❌ 변경 감지 불가
  ...
}
```

```dart
// ❌ 메서드에서 ref.watch 사용
Future<void> deleteCard(String id) async {
  final deleteCard = ref.watch(deleteCardUseCaseProvider);  // ❌ 메서드에선 read
  ...
}
```

---

## State 정의 패턴

### freezed로 상태 정의

```dart
// ✅ 기본 상태 + 에러 상태를 sealed로 분리
@freezed
class CardListState with _$CardListState {
  const factory CardListState({
    @Default([]) List<CardEntity> cards,
    @Default(false) bool isDeleting,
  }) = _CardListState;

  const factory CardListState.error(AppFailure failure) = _CardListStateError;
}
```

### AsyncValue와 함께 사용

```dart
// ✅ AsyncNotifier가 제공하는 AsyncValue 활용
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    // 반환 타입이 FutureOr<T>이면 자동으로
    // AsyncLoading → AsyncData 또는 AsyncError로 전환
    ...
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();  // 로딩 상태로 전환
    state = await AsyncValue.guard(() => build());  // 재실행
  }
}
```

### 금지 패턴

```dart
// ❌ 수동 copyWith
class CardListState {
  final List<CardEntity> cards;
  CardListState copyWith({List<CardEntity>? cards}) {
    return CardListState(cards: cards ?? this.cards);
  }
}
```

```dart
// ❌ 상태 안에 isLoading 수동 관리
@freezed
class CardListState with _$CardListState {
  const factory CardListState({
    @Default(false) bool isLoading,  // ❌ AsyncValue가 처리
    @Default(false) bool hasError,   // ❌ AsyncValue가 처리
    ...
  }) = _CardListState;
}
```

---

## Provider 조합 패턴

### 다른 Provider에 의존하기

```dart
// ✅ 인증 상태에 따라 카드 목록을 다르게 조회
@riverpod
class CardListViewModel extends _$CardListViewModel {
  @override
  FutureOr<CardListState> build() async {
    final authState = ref.watch(authViewModelProvider);
    final getCards = ref.watch(getCardsUseCaseProvider);

    // 인증 상태가 바뀌면 자동으로 리빌드
    final userId = switch (authState) {
      AsyncData(:final value) => switch (value) {
        AuthStateAuthenticated(:final user) => user.id,
        _ => null,
      },
      _ => null,
    };

    if (userId == null) return const CardListState();

    final result = await getCards(userId: userId);
    return switch (result) {
      Success(:final data) => CardListState(cards: data),
      Failure(:final failure) => CardListState.error(failure),
    };
  }
}
```

### family — 파라미터가 있는 Provider

```dart
// ✅ @riverpod에서 build()에 파라미터를 추가하면 자동으로 family
@riverpod
class CardDetailViewModel extends _$CardDetailViewModel {
  @override
  FutureOr<CardDetailState> build(String cardId) async {
    final getCard = ref.watch(getCardUseCaseProvider);
    final result = await getCard(cardId);
    ...
  }
}

// 사용 시
ref.watch(cardDetailViewModelProvider('card_123'));
```

```dart
// ❌ 수동 family 선언
final cardDetailProvider = FutureProvider.family<CardDetailState, String>(
  (ref, cardId) async { ... },
);
```

---

## UseCase / Repository Provider 등록

```dart
// ✅ UseCase Provider — Repository를 주입받아 UseCase 생성
@riverpod
GetCardsUseCase getCardsUseCase(Ref ref) {
  final repository = ref.watch(cardRepositoryProvider);
  return GetCardsUseCase(repository);
}

// ✅ Repository 인터페이스 → 구현체 바인딩
@riverpod
CardRepository cardRepository(Ref ref) {
  final dataSource = ref.watch(cardDataSourceProvider);
  return CardRepositoryImpl(dataSource);
}

// ✅ DataSource Provider
@riverpod
CardDataSource cardDataSource(Ref ref) {
  final client = ref.watch(dioProvider);
  return CardDataSource(client);
}
```

DI 체인: `ViewModel → UseCase → Repository → DataSource → Dio`
모두 `ref.watch`로 연결되며, 하위 의존성이 바뀌면 상위도 자동 리빌드됩니다.

---

## 화면에서 상태 소비

### when으로 분기

```dart
// ✅ AsyncValue의 when으로 로딩/에러/데이터 분기
class CardListScreen extends ConsumerWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardListViewModelProvider);

    return state.when(
      data: (cardState) => _CardListBody(cardState: cardState),
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(error: error),
    );
  }
}
```

### 액션 호출

```dart
// ✅ notifier를 통해 메서드 호출
ElevatedButton(
  onPressed: () => ref
      .read(cardListViewModelProvider.notifier)
      .deleteCard(card.id),
  child: const Text('삭제'),
)
```

### 금지 패턴

```dart
// ❌ Widget에서 비즈니스 로직 수행
class CardListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardListViewModelProvider);
    // ❌ 필터링/정렬은 ViewModel에서
    final sorted = state.value?.cards.toList()
      ?..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    ...
  }
}
```

---

## 흔한 실수 모음

### 1. invalidateSelf 대신 state 직접 조작

```dart
// ✅ 목록 새로고침이 필요할 때
case Success():
  ref.invalidateSelf();  // ✅ build()를 다시 실행

// ❌ 삭제 후 수동으로 목록에서 제거
state = AsyncData(currentState.copyWith(
  cards: currentState.cards.where((c) => c.id != id).toList(),
));
// ❌ 서버 데이터와 불일치 위험
```

### 2. dispose 타이밍 무시

```dart
// ✅ autoDispose Provider에서 리소스 정리
@riverpod
class SearchViewModel extends _$SearchViewModel {
  Timer? _debounceTimer;

  @override
  SearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();  // ✅ Provider 해제 시 정리
    });
    return const SearchState();
  }
}
```

### 3. 순환 의존

```dart
// ❌ Provider A가 B를 watch, B가 A를 watch → 무한 루프

// 해결: 공통 의존성을 별도 Provider로 추출
```

### 4. build() 안에서 부수효과 실행

```dart
// ❌ build()에서 네비게이션이나 다이얼로그 호출
@override
FutureOr<CardListState> build() async {
  ...
  if (result case Failure()) {
    Navigator.of(context).pop();  // ❌ build는 순수해야 함
  }
}

// ✅ ref.listen으로 부수효과 분리 (Screen에서)
ref.listen(cardListViewModelProvider, (prev, next) {
  if (next case AsyncError(:final error)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
});
```