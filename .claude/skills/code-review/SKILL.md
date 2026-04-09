---
name: code-review
description: >
  Flutter Clean Architecture 코드 리뷰어입니다. git diff로 변경된 Dart 파일을 수집하고,
  프로젝트 아키텍처 규칙 위반을 심각도(Critical/High/Medium/Low)별로 분류해 리포트를 생성합니다.
  코드를 수정하지 않고 리포트만 출력합니다(읽기 전용).

  다음 중 하나라도 해당하면 반드시 이 스킬을 사용하세요:
  - "코드 리뷰해줘", "리뷰해줘", "변경사항 검토", "PR 전 점검" 요청 시
  - "/code-review" 커맨드 입력 시
  - "아키텍처 규칙 위반 확인", "레이어 의존성 체크" 요청 시
  - 커밋/PR 전에 코드 품질을 확인하고 싶을 때
---

# code-review 스킬

## 목적

변경된 파일을 이 프로젝트의 Clean Architecture 규칙에 따라 검사하고,
위반 사항을 심각도별로 정리한 리포트를 생성합니다.
코드는 절대 수정하지 않습니다.

---

## 실행 순서

1. **변경 파일 수집** — `git diff --name-only HEAD`로 Dart 파일 목록 추출
2. **파일 읽기** — 각 `.dart` 파일을 읽어 위반 패턴 검사
3. **리포트 생성** — 심각도별로 분류해 출력

---

## 검사 항목 및 심각도

### 🔴 Critical — 아키텍처 계약 위반

| 규칙 ID | 설명 | 감지 패턴 |
|---------|------|-----------|
| C1 | **presentation → data 직접 import** | presentation/ 경로 파일에서 `import '...data/...` 또는 `import 'package:.../data/` |
| C2 | **domain에서 Flutter import** | domain/ 경로 파일에서 `import 'package:flutter` 또는 `import 'dart:ui'` |
| C3 | **ViewModel에서 Repository 직접 호출** | view_model 파일에서 `ref.watch(.*[Rr]epository` 또는 `ref.read(.*[Rr]epository` |

### 🟠 High — 컨벤션 위반

| 규칙 ID | 설명 | 감지 패턴 |
|---------|------|-----------|
| H1 | **Entity에 fromJson/toJson** | entity 파일에서 `fromJson` 또는 `toJson` 존재 |
| H2 | **Model에 snake_case Dart 필드** | model 파일에서 `required.*_[a-z]` 패턴 (단, `@JsonKey`로 감싼 경우 제외) |
| H3 | **build()에 비즈니스 로직** | Screen/Widget 파일 `build(` 메서드 내 `.where(`, `.sort(`, `.filter(`, `await ` 존재 |
| H4 | **StateNotifier 사용** | `extends StateNotifier` 또는 `StateNotifierProvider` 사용 |

### 🟡 Medium — 코드 품질 문제

| 규칙 ID | 설명 | 감지 패턴 |
|---------|------|-----------|
| M1 | **build()에서 ref.read** | ConsumerWidget 파일의 `build(` 메서드 내 `ref.read(` |
| M2 | **await 후 context.mounted 누락** | `await ` 이후에 `context.` 사용이 있지만 `context.mounted` 체크가 없음 |
| M3 | **print() 사용** | `print(` 또는 `debugPrint(` 존재 |
| M4 | **dynamic 타입** | `dynamic ` 또는 `as dynamic` 또는 `Map<String, dynamic>` 이외의 `dynamic` |

### 🔵 Low — 유지보수 문제

| 규칙 ID | 설명 | 감지 패턴 |
|---------|------|-----------|
| L1 | **파일 200줄 초과** | 파일 전체 줄 수 > 200 |

---

## 검사 방법

각 파일에 대해 다음을 확인합니다:

1. **파일 경로**로 레이어 판단:
   - `presentation/` 포함 → presentation 레이어
   - `domain/` 포함 → domain 레이어
   - `data/` 포함 → data 레이어
   - `view_model` 포함 → ViewModel 파일
   - `_entity.dart` 으로 끝남 → Entity 파일
   - `_model.dart` 으로 끝남 → Model 파일 (단, `view_model` 제외)
   - `_screen.dart` 또는 `_widget.dart` 으로 끝남 → Widget 파일

2. **파일 내용**을 읽어 각 레이어에 해당하는 규칙 검사

3. **줄 번호** 포함해서 보고 (가능한 경우)

---

## 리포트 형식

```
## 코드 리뷰 리포트

**검사 파일**: N개
**위반 건수**: Critical N / High N / Medium N / Low N

---

### 🔴 Critical

**[C1] presentation → data 직접 import**
- `lib/features/card/presentation/screens/card_list_screen.dart` (line 3)
  ```dart
  import 'package:app/features/card/data/models/card_model.dart'; // ❌
  ```
  → 참조: docs/architecture/layer-rules.md

---

### 🟠 High
...

---

### 🟡 Medium
...

---

### 🔵 Low
...
```

위반이 없으면:

```
## 코드 리뷰 리포트

✅ 리뷰 통과 — 변경된 N개 파일에서 아키텍처 규칙 위반이 발견되지 않았습니다.
```

---

## 참조 문서 경로

각 위반에 아래 경로를 함께 제시합니다:

| 위반 유형 | 참조 문서 |
|----------|----------|
| 레이어 의존성 (C1, C2, C3) | `docs/architecture/layer-rules.md` |
| Entity/Model 패턴 (H1, H2) | `docs/architecture/patterns.md` |
| ViewModel/Widget 패턴 (H3, H4, M1) | `docs/architecture/riverpod-patterns.md` |
| context.mounted (M2) | `CLAUDE.md` → 절대 규칙 |
| print/dynamic (M3, M4) | `CLAUDE.md` → 절대 규칙 |
| 파일 길이 (L1) | `CLAUDE.md` → 코딩 컨벤션 |

---

## 주의사항

- 코드를 수정하지 않습니다. 리포트 출력만 합니다.
- `git diff --name-only HEAD`로 변경 파일을 가져오되, 실패하면 `git status --short`로 대체합니다.
- `.g.dart`, `.freezed.dart` 파일은 생성 파일이므로 검사에서 제외합니다.
- M4(dynamic) 검사에서 `Map<String, dynamic>`은 허용 패턴이므로 제외합니다.
- M2(context.mounted) 검사는 false positive가 많을 수 있으므로 `await` 직후 동일 함수 내 `context.` 사용을 확인하는 방식으로 판단합니다.
