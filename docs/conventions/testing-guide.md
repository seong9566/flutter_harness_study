# Testing Guide — 테스트 패턴 가이드

## 이 문서의 목적

CLAUDE.md에 명시된 테스트 규칙의 **파일 배치, Mock 패턴, 레이어별 테스트 전략**을 다룹니다.

---

## 파일 배치

소스 파일과 동일한 경로 구조를 `test/` 아래에 미러링합니다.

```
lib/features/card/domain/usecases/get_cards_usecase.dart
→ test/features/card/domain/usecases/get_cards_usecase_test.dart

lib/features/card/data/repositories/card_repository_impl.dart
→ test/features/card/data/repositories/card_repository_impl_test.dart

lib/features/card/presentation/view_models/card_list_view_model.dart
→ test/features/card/presentation/view_models/card_list_view_model_test.dart

lib/features/card/presentation/screens/card_list_screen.dart
→ test/features/card/presentation/screens/card_list_screen_test.dart
```

---

## Mock 라이브러리: mocktail

`mockito`가 아닌 `mocktail`을 사용합니다. 코드 생성 없이 Mock을 만들 수 있습니다.

### Mock 클래스 생성

```dart
import 'package:mocktail/mocktail.dart';

// ✅ mocktail — 코드 생성 불필요
class MockCardRepository extends Mock implements CardRepository {}
class MockGetCardsUseCase extends Mock implements GetCardsUseCase {}
class MockCardDataSource extends Mock implements CardDataSource {}
```

```dart
// ❌ mockito — 코드 생성 필요, 사용 금지
@GenerateMocks([CardRepository])
void main() {}
```

### when / verify 패턴

```dart
// ✅ 성공 케이스 stubbing
when(() => mockRepository.getCards())
    .thenAnswer((_) async => Success([mockCardEntity]));

// ✅ 실패 케이스 stubbing
when(() => mockRepository.getCards())
    .thenAnswer((_) async => Failure(AppFailure.server('서버 에러')));

// ✅ 호출 검증
verify(() => mockRepository.getCards()).called(1);

// ✅ 호출되지 않았는지 검증
verifyNever(() => mockRepository.deleteCard(any()));
```

### registerFallbackValue

mocktail에서 `any()`를 커스텀 타입에 사용하려면 fallback 등록이 필요합니다.

```dart
// ✅ setUpAll에서 등록
setUpAll(() {
registerFallbackValue(
const CardEntity(
id: '',
title: '',
description: '',
createdAt: DateTime(2024),
isCompleted: false,
),
);
});

// 이후 any()로 사용 가능
when(() => mockRepository.updateCard(any()))
    .thenAnswer((_) async => const Success(null));
```

---

## 레이어별 테스트 전략

### Domain — UseCase 테스트 (필수)

UseCase는 순수 Dart이므로 가장 테스트하기 쉽습니다. Repository를 Mock합니다.

```dart
void main() {
  late CompleteCardUseCase useCase;
  late MockCardRepository mockRepository;

  setUp(() {
    mockRepository = MockCardRepository();
    useCase = CompleteCardUseCase(mockRepository);
  });

  group('CompleteCardUseCase', () {
    test('미완료 카드를 완료 처리한다', () async {
      // Arrange
      final card = CardEntity(
        id: '1',
        title: '테스트',
        description: '',
        createdAt: DateTime.now(),
        isCompleted: false,
      );

      when(() => mockRepository.getCardById('1'))
          .thenAnswer((_) async => Success(card));
      when(() => mockRepository.updateCard(any()))
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase('1');

      // Assert
      expect(result, isA<Success>());
      verify(() => mockRepository.updateCard(
        any(that: isA<CardEntity>().having(
              (c) => c.isCompleted, 'isCompleted', true,
        )),
      )).called(1);
    });

    test('이미 완료된 카드는 에러를 반환한다', () async {
      // Arrange
      final card = CardEntity(
        id: '1',
        title: '테스트',
        description: '',
        createdAt: DateTime.now(),
        isCompleted: true,  // 이미 완료
      );

      when(() => mockRepository.getCardById('1'))
          .thenAnswer((_) async => Success(card));

      // Act
      final result = await useCase('1');

      // Assert
      expect(result, isA<Failure>());
      verifyNever(() => mockRepository.updateCard(any()));
    });
  });
}
```

### Data — Repository 테스트 (필수)

DataSource를 Mock하고, Mapper 변환과 에러 처리를 검증합니다.

```dart
void main() {
  late CardRepositoryImpl repository;
  late MockCardDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockCardDataSource();
    repository = CardRepositoryImpl(mockDataSource);
  });

  group('CardRepositoryImpl.getCards', () {
    test('DataSource의 Model을 Entity로 변환하여 Success를 반환한다', () async {
      // Arrange
      final models = [
        CardModel(
          id: '1',
          title: '테스트',
          description: '',
          createdAt: '2024-01-01T00:00:00Z',
          isCompleted: false,
          authorName: 'author',
          updatedAt: '2024-01-01T00:00:00Z',
        ),
      ];

      when(() => mockDataSource.fetchCards())
          .thenAnswer((_) async => models);

      // Act
      final result = await repository.getCards();

      // Assert
      expect(result, isA<Success<List<CardEntity>>>());
      final cards = (result as Success<List<CardEntity>>).data;
      expect(cards.length, 1);
      expect(cards.first.id, '1');
      expect(cards.first.isCompleted, false);
    });

    test('DataSource 예외 시 Failure를 반환한다', () async {
      // Arrange
      when(() => mockDataSource.fetchCards())
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/cards'),
        message: '네트워크 에러',
      ));

      // Act
      final result = await repository.getCards();

      // Assert
      expect(result, isA<Failure>());
    });
  });
}
```

### Presentation — ViewModel 테스트 (권장)

UseCase를 Mock하고, 상태 전이를 검증합니다.

```dart
void main() {
  late ProviderContainer container;
  late MockGetCardsUseCase mockGetCards;
  late MockDeleteCardUseCase mockDeleteCard;

  setUp(() {
    mockGetCards = MockGetCardsUseCase();
    mockDeleteCard = MockDeleteCardUseCase();

    container = ProviderContainer(
      overrides: [
        getCardsUseCaseProvider.overrideWithValue(mockGetCards),
        deleteCardUseCaseProvider.overrideWithValue(mockDeleteCard),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('초기 로드 시 카드 목록을 가져온다', () async {
    // Arrange
    final cards = [
      CardEntity(
        id: '1',
        title: '테스트',
        description: '',
        createdAt: DateTime.now(),
        isCompleted: false,
      ),
    ];

    when(() => mockGetCards())
        .thenAnswer((_) async => Success(cards));

    // Act
    final viewModel = container.read(cardListViewModelProvider.future);
    final state = await viewModel;

    // Assert
    expect(state.cards.length, 1);
    expect(state.cards.first.title, '테스트');
  });
}
```

### Presentation — Widget 테스트 (선택)

ProviderScope.overrides로 의존성을 주입합니다.

```dart
void main() {
  late MockGetCardsUseCase mockGetCards;

  setUp(() {
    mockGetCards = MockGetCardsUseCase();
  });

  testWidgets('카드 목록이 표시된다', (tester) async {
    // Arrange
    final cards = [
      CardEntity(
        id: '1',
        title: '테스트 카드',
        description: '',
        createdAt: DateTime.now(),
        isCompleted: false,
      ),
    ];

    when(() => mockGetCards())
        .thenAnswer((_) async => Success(cards));

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getCardsUseCaseProvider.overrideWithValue(mockGetCards),
        ],
        child: const MaterialApp(
          home: CardListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert
    expect(find.text('테스트 카드'), findsOneWidget);
  });

  testWidgets('로딩 중에는 LoadingView가 표시된다', (tester) async {
    // Arrange — 응답을 지연시킴
    when(() => mockGetCards()).thenAnswer(
          (_) => Future.delayed(
        const Duration(seconds: 10),
            () => Success(<CardEntity>[]),
      ),
    );

    // Act
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getCardsUseCaseProvider.overrideWithValue(mockGetCards),
        ],
        child: const MaterialApp(
          home: CardListScreen(),
        ),
      ),
    );

    // pump 한 번만 — settle하지 않아야 로딩 상태 확인 가능
    await tester.pump();

    // Assert
    expect(find.byType(LoadingView), findsOneWidget);
  });
}
```

---

## 테스트 필수 / 권장 범위

| 레이어 | 대상 | 필수 여부 |
|---|---|---|
| domain | UseCase | **필수** |
| data | Repository 구현체 | **필수** |
| data | Mapper | 복잡한 변환이 있으면 필수 |
| presentation | ViewModel | 권장 |
| presentation | Widget | 핵심 화면만 선택적 |

---

## 테스트 작성 규칙

### Arrange-Act-Assert 패턴

모든 테스트는 3단계로 구성합니다. 주석으로 구분하세요.

```dart
test('설명', () async {
// Arrange — 준비
...

// Act — 실행
...

// Assert — 검증
...
});
```

### group으로 묶기

```dart
group('GetCardsUseCase', () {
test('카드 목록을 반환한다', () async { ... });
test('Repository 실패 시 Failure를 반환한다', () async { ... });
});

group('CompleteCardUseCase', () {
test('미완료 카드를 완료 처리한다', () async { ... });
test('이미 완료된 카드는 에러를 반환한다', () async { ... });
});
```

### 테스트 이름 규칙

```dart
// ✅ 한국어로, "~한다" 형태
test('미완료 카드를 완료 처리한다', ...);
test('서버 에러 시 Failure를 반환한다', ...);
test('빈 목록일 때 EmptyView를 표시한다', ...);

// ❌ 모호한 이름
test('test1', ...);
test('카드 테스트', ...);
test('성공', ...);
```

---

## 커버리지

### 목표: 90% 이상

```bash
# 커버리지 측정 + HTML 리포트 + 90% 게이트
make coverage

# 미테스트 파일 포함한 정확한 커버리지 (CI용)
make coverage-all

# 브라우저에서 리포트 확인
make coverage-open
```

### 커버리지에서 제외되는 파일

- `*.g.dart` — freezed/riverpod 생성 파일
- `*.freezed.dart` — freezed 생성 파일
- `*.gen.dart` — 기타 생성 파일
- `*/l10n/*.dart` — 다국어 생성 파일
- `*/router/*.dart` — GoRouter 설정

### 커버리지 우선순위

테스트 시간이 한정적이면 이 순서로 작성합니다:

1. **UseCase** — 비즈니스 로직의 핵심, 가장 높은 ROI
2. **Repository 구현체** — 에러 처리와 Mapper 변환 검증
3. **ViewModel** — 상태 전이 검증
4. **Mapper** — 복잡한 변환이 있는 경우
5. **Widget** — 핵심 화면의 렌더링 검증

---

## 흔한 실수

### 1. async 테스트에서 await 누락

```dart
// ❌ await 없이 Future 반환
test('카드를 가져온다', () {
final result = useCase();  // ❌ await 누락 → 테스트가 검증 전에 통과
expect(result, isA<Success>());
});

// ✅
test('카드를 가져온다', () async {
final result = await useCase();
expect(result, isA<Success>());
});
```

### 2. pumpAndSettle vs pump

```dart
// pumpAndSettle — 모든 애니메이션/비동기 완료까지 대기
// → 최종 상태를 검증할 때
await tester.pumpAndSettle();

// pump — 한 프레임만 진행
// → 로딩 상태 등 중간 상태를 검증할 때
await tester.pump();
```

### 3. tearDown에서 container.dispose 누락

```dart
// ✅ 반드시 dispose
tearDown(() => container.dispose());

// ❌ dispose 누락 → Provider 상태가 다음 테스트에 누출
```