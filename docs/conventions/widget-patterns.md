# Widget Patterns — Widget 작성 패턴 가이드

## 이 문서의 목적

CLAUDE.md에 명시된 Widget 규칙의 **분리 기준, 구성 패턴, 흔한 실수**를 다룹니다.
ViewModel과의 연결 방법은 `riverpod-patterns.md`를 참조하세요.

---

## Widget 타입 선택

### 기본 원칙: ConsumerWidget 우선

| 상태 관리 필요? | Controller 필요? | 선택 |
|---|---|---|
| Riverpod으로 충분 | 없음 | `ConsumerWidget` |
| Riverpod + TextEditingController 등 | 있음 | `ConsumerStatefulWidget` |
| Riverpod 불필요, 순수 UI | 없음 | `StatelessWidget` |

```dart
// ✅ 대부분의 경우
class CardListScreen extends ConsumerWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ...
  }
}
```

```dart
// ✅ Controller가 필요한 경우
class CardFormScreen extends ConsumerStatefulWidget {
  const CardFormScreen({super.key});

  @override
  ConsumerState<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends ConsumerState<CardFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

```dart
// ❌ StatefulWidget + setState로 상태 관리
class CardListScreen extends StatefulWidget {
  ...
}

class _CardListScreenState extends State<CardListScreen> {
  List<CardEntity> _cards = [];  // ❌ Riverpod으로 관리
  bool _isLoading = false;       // ❌ AsyncValue가 처리

  void _fetchCards() async {
    setState(() => _isLoading = true);  // ❌
    ...
  }
}
```

---

## 파일 크기 제한 (200줄)

### 왜 200줄인가

- Claude가 긴 파일을 생성하면 컨텍스트 윈도우를 빠르게 소모합니다.
- 200줄을 넘으면 대부분 여러 책임이 섞여 있다는 신호입니다.
- 작은 Widget은 테스트하기 쉽고 재사용 가능성이 높습니다.

### 분리 기준

| 신호 | 분리 방법 |
|---|---|
| `build()` 안에 조건 분기가 3개 이상 | 각 분기를 별도 Widget으로 |
| 리스트 아이템이 복잡 | `*_item_widget.dart`로 분리 |
| 앱바, 바텀시트, 다이얼로그 | 각각 별도 Widget 파일로 |
| 동일 패턴이 2곳 이상에서 반복 | `shared/widgets/`로 추출 |

### 분리 예시

```
# ❌ 하나의 거대한 파일
card_list_screen.dart (400줄)

# ✅ 역할별로 분리
card_list_screen.dart        # Screen 진입점, Scaffold 구성 (~60줄)
card_list_body.dart          # 목록 본문 (~80줄)
card_list_item.dart          # 개별 카드 아이템 (~70줄)
card_list_empty_view.dart    # 빈 상태 표시 (~30줄)
```

### 분리할 때 데이터 전달

```dart
// ✅ 필요한 데이터만 파라미터로 전달
class CardListItem extends StatelessWidget {
  const CardListItem({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  final CardEntity card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

```dart
// ❌ 하위 Widget에서 ref.watch로 전체 상태를 다시 읽기
class CardListItem extends ConsumerWidget {
  const CardListItem({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ❌ 부모가 이미 가진 데이터를 다시 watch
    final card = ref.watch(cardListViewModelProvider).value!.cards[index];
    ...
  }
}
```

---

## build() 메서드 규칙

### build() 안에서 하면 안 되는 것

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ❌ 비즈니스 로직
  final filtered = cards.where((c) => c.isActive).toList();

  // ❌ 데이터 포맷팅
  final price = '₩${card.price.toStringAsFixed(0)}';

  // ❌ 비동기 호출
  final data = await repository.fetchCards();

  // ❌ 복잡한 계산
  final totalPrice = cards.fold(0, (sum, c) => sum + c.price);

  return ...;
}
```

### 어디서 처리해야 하는가

| 작업 | 처리 위치 |
|---|---|
| 필터링, 정렬, 검색 | ViewModel |
| 금액/날짜 포맷팅 | Entity의 getter 또는 별도 Formatter 유틸 |
| 합계, 통계 계산 | UseCase 또는 ViewModel |
| API 호출 | ViewModel → UseCase → Repository |

---

## 스타일링 규칙

### 하드코딩 금지

```dart
// ❌ 매직 넘버
Padding(padding: EdgeInsets.all(16))
SizedBox(height: 8)
BorderRadius.circular(12)

// ✅ 상수 사용
Padding(padding: EdgeInsets.all(AppSpacing.md))
SizedBox(height: AppSpacing.xs)
BorderRadius.circular(AppSpacing.sm)
```

### 색상, 텍스트 스타일

```dart
// ❌ 하드코딩
Text('제목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
Container(color: Color(0xFF2196F3))

// ✅ 테마에서 가져오기
Text('제목', style: Theme.of(context).textTheme.titleMedium)
Container(color: Theme.of(context).colorScheme.primary)

// ✅ 또는 앱 상수
Text('제목', style: AppTypography.titleMedium)
Container(color: AppColors.primary)
```

---

## 자주 쓰는 Widget 패턴

### 로딩 / 에러 / 빈 상태 처리

```dart
// ✅ AsyncValue.when + 공용 Widget 조합
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(cardListViewModelProvider);

  return state.when(
    data: (cardState) => cardState.cards.isEmpty
        ? const EmptyView(message: '카드가 없습니다')
        : CardListBody(cards: cardState.cards),
    loading: () => const LoadingView(),
    error: (error, _) => ErrorView(
      error: error,
      onRetry: () => ref.invalidate(cardListViewModelProvider),
    ),
  );
}
```

### 폼 입력

```dart
// ✅ ConsumerStatefulWidget + Controller + ViewModel 메서드 호출
class _CardFormScreenState extends ConsumerState<CardFormScreen> {
  late final TextEditingController _titleController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(cardFormViewModelProvider.notifier).createCard(
      title: _titleController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 제출 결과 리스닝 (부수효과)
    ref.listen(cardFormViewModelProvider, (prev, next) {
      if (next case AsyncData()) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
      }
    });

    return Form(
      key: _formKey,
      child: ...
    );
  }
}
```

### context.mounted 가드

```dart
// ✅ 비동기 작업 후 context 사용 시 반드시 체크
Future<void> _onDelete() async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;

  await ref.read(cardListViewModelProvider.notifier).deleteCard(card.id);

  if (!context.mounted) return;  // ✅ 필수
  Navigator.of(context).pop();
}
```

```dart
// ❌ mounted 체크 없이 context 사용
Future<void> _onDelete() async {
  await ref.read(cardListViewModelProvider.notifier).deleteCard(card.id);
  Navigator.of(context).pop();  // ❌ Widget이 이미 dispose됐을 수 있음
}
```

---

## const 생성자 체크리스트

```dart
// ✅ 상태가 없는 Widget은 반드시 const 생성자
class CardEmptyView extends StatelessWidget {
  const CardEmptyView({super.key});  // ✅ const
  ...
}

// ✅ 사용할 때도 const
body: const CardEmptyView(),  // ✅

// ❌ const 가능한데 빠뜨린 경우
body: CardEmptyView(),  // ❌ const 누락
```

Widget에 `const` 생성자가 가능한 조건:
- 모든 필드가 `final`
- 생성자 파라미터에 런타임 값이 없음 (콜백 제외)
- 부모 클래스도 const 생성자를 가짐