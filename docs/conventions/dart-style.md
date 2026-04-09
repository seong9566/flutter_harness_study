# Dart Style — Dart 스타일 가이드

## 이 문서의 목적

CLAUDE.md에 명시된 코딩 규칙의 **상세 설명과 근거**를 다룹니다.
CLAUDE.md의 규칙이 우선이며, 이 문서는 보충 자료입니다.

---

## 네이밍

### 파일

| 대상 | 규칙 | 예시 |
|---|---|---|
| 일반 파일 | `snake_case` | `card_repository.dart` |
| freezed 모델 | `snake_case` | `card_entity.dart` |
| 생성 파일 | 소스 파일명 + 접미사 | `card_entity.freezed.dart`, `card_entity.g.dart` |
| 테스트 파일 | 소스 파일명 + `_test` | `card_entity_test.dart` |

### 클래스 / 타입

| 대상 | 규칙 | 예시 |
|---|---|---|
| 클래스 | `PascalCase` | `CardEntity`, `CardRepositoryImpl` |
| enum | `PascalCase` | `CardStatus` |
| enum 값 | `camelCase` | `CardStatus.inProgress` |
| typedef | `PascalCase` | `JsonMap` |
| 제네릭 타입 파라미터 | 대문자 한 글자 | `T`, `E`, `K`, `V` |

### 변수 / 함수 / 상수

| 대상 | 규칙 | 예시 |
|---|---|---|
| 변수, 함수 | `camelCase` | `getCards()`, `isCompleted` |
| private 멤버 | `_camelCase` | `_repository`, `_fetchData()` |
| 상수 | `camelCase` | `defaultPageSize` (Dart 공식 컨벤션) |
| static const | `camelCase` | `static const maxRetryCount = 3` |

**주의:** Dart에서는 상수도 `camelCase`입니다. `SCREAMING_SNAKE_CASE`는 사용하지 않습니다.

---

## 문서화

### public API에 `///` doc comment 작성

```dart
// ✅ 클래스에 doc comment
/// 카드 관련 비즈니스 로직을 처리하는 UseCase.
///
/// [CardRepository]를 통해 데이터를 조회하고,
/// 완료 상태 변경 시 유효성 검증을 수행합니다.
class CompleteCardUseCase {
  ...
}

// ✅ public 메서드에 doc comment
/// 카드 ID로 카드를 조회합니다.
///
/// 카드가 존재하지 않으면 [AppFailure.notFound]를 반환합니다.
Future<Result<CardEntity>> call(String cardId) async {
  ...
}
```

### doc comment 규칙

- "왜"를 설명하세요. "무엇"은 코드 자체가 말합니다.
- 첫 줄은 한 문장 요약. 상세 설명이 필요하면 빈 줄 후 추가합니다.
- `[ClassName]`, `[methodName]` 형식으로 다른 API를 참조합니다.
- private 멤버(`_`로 시작)에는 doc comment가 필수가 아닙니다. 복잡한 로직에만 추가합니다.
- 버전 이력이나 "fixed by" 같은 내용은 쓰지 마세요. Git 이력이 담당합니다.

### 인라인 주석

```dart
// ✅ 의도가 불명확한 곳에만
// API가 삭제된 카드도 반환하므로, 클라이언트에서 필터링
final activeCards = cards.where((c) => !c.isDeleted).toList();

// ❌ 코드를 그대로 반복하는 주석
// 카드 목록을 가져온다
final cards = await repository.getCards();
```

---

## 타입 안전성

### `dynamic` 사용 금지

```dart
// ❌ dynamic
dynamic result = await fetchData();

// ✅ 명시적 타입
final Map<String, Object?> result = await fetchData();

// ✅ 타입을 모를 때는 Object?
Object? unknownValue = json['data'];
```

### `late` 최소화

`late`는 초기화 시점을 보장할 수 없으면 런타임 에러를 유발합니다.

```dart
// ❌ late 남용
late final CardEntity card;

void init() {
  card = fetchCard();  // init이 호출되지 않으면 LateInitializationError
}

// ✅ nullable + null check
CardEntity? _card;

void init() {
  _card = fetchCard();
}

void doSomething() {
  final card = _card;
  if (card == null) return;
  // card 사용
}
```

**late를 허용하는 경우:**
- `late final`로 `initState()`에서 반드시 초기화되는 Controller류
- lazy 초기화가 명확히 보장되는 경우

### 타입 추론

```dart
// ✅ 우변에서 타입이 명확할 때는 생략 가능
final cards = <CardEntity>[];
final name = 'Flutter';
final count = 0;

// ✅ 우변에서 타입이 불명확할 때는 명시
final List<CardEntity> result = ref.watch(cardProvider).value ?? [];
```

---

## part / part of 규칙

코드 생성 파일에만 사용합니다. 일반 코드 분리 목적으로는 사용하지 않습니다.

```dart
// ✅ freezed, riverpod 생성 파일
part 'card_entity.freezed.dart';
part 'card_entity.g.dart';

// ❌ 코드 분리 목적
part 'card_entity_extensions.dart';  // ❌ 별도 파일로 import
```

---

## import 정리

### 순서

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. 외부 패키지 (알파벳순)
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// 4. 프로젝트 내부 (알파벳순)
import 'package:app/core/error/result.dart';
import 'package:app/features/card/domain/entities/card_entity.dart';
```

### 금지

```dart
// ❌ 상대 경로 import
import '../../../core/utils/logger.dart';

// ✅ 패키지 경로 import
import 'package:app/core/utils/logger.dart';
```

---

## 기타 스타일

### 매직 넘버 금지

```dart
// ❌
padding: EdgeInsets.all(16.0),
maxLines: 3,

// ✅
padding: EdgeInsets.all(AppSpacing.md),
maxLines: AppConstants.cardMaxLines,
```

### guard clause (조기 반환)

```dart
// ❌ 깊은 중첩
Future<void> submit() async {
  if (state.value != null) {
    if (state.value!.isValid) {
      if (!_isSubmitting) {
        ...
      }
    }
  }
}

// ✅ 조기 반환으로 중첩 최소화
Future<void> submit() async {
  final currentState = state.value;
  if (currentState == null) return;
  if (!currentState.isValid) return;
  if (_isSubmitting) return;

  ...
}
```

### const 활용

```dart
// ✅ 상태가 없는 Widget은 const 생성자
class CardEmptyView extends StatelessWidget {
  const CardEmptyView({super.key});
  ...
}

// ✅ 사용 시에도 const
const CardEmptyView()

// ❌ const가 가능한데 빠뜨린 경우
CardEmptyView()  // lint 경고 발생
```

### trailing comma

```dart
// ✅ 파라미터가 여러 줄일 때 trailing comma
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
    ),  // ← trailing comma
  );
}
```