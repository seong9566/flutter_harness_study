# Design System — 디자인 시스템 가이드

## 이 문서의 목적

CLAUDE.md에 명시된 스타일링 규칙의 **색상, 타이포그래피, 간격, 컴포넌트 규칙**을 다룹니다.
모든 UI 수치는 `lib/core/theme/` 아래의 상수를 사용하며, 하드코딩은 금지입니다.

---

## 파일 구조

```
lib/core/theme/
├── app_theme.dart          # ThemeData 정의 (Light / Dark)
├── app_colors.dart         # 색상 팔레트
├── app_typography.dart     # 텍스트 스타일
└── app_spacing.dart        # 간격 상수 (패딩, 마진, 라운딩)
```

---

## 색상 (AppColors)

### 시맨틱 색상

용도별로 이름을 붙인 색상만 사용합니다. 원시 색상값을 직접 쓰지 마세요.

| 이름 | 용도 |
|---|---|
| `AppColors.primary` | 주요 액션, CTA 버튼, 강조 |
| `AppColors.onPrimary` | primary 위의 텍스트/아이콘 |
| `AppColors.secondary` | 보조 액션, 태그, 칩 |
| `AppColors.surface` | 카드, 시트, 다이얼로그 배경 |
| `AppColors.onSurface` | surface 위의 텍스트 |
| `AppColors.background` | 화면 전체 배경 |
| `AppColors.error` | 에러 상태, 유효성 실패 |
| `AppColors.onError` | error 위의 텍스트/아이콘 |
| `AppColors.outline` | 테두리, 구분선 |
| `AppColors.disabled` | 비활성 상태 |

### 사용 방법

```dart
// ✅ AppColors 또는 Theme에서 가져오기
Container(color: AppColors.surface)
Icon(Icons.check, color: Theme.of(context).colorScheme.primary)

// ❌ 하드코딩
Container(color: Color(0xFFF5F5F5))
Container(color: Colors.blue)
```

### 다크 모드

`app_theme.dart`에서 Light/Dark 테마를 각각 정의합니다.
Widget에서 분기하지 마세요.

```dart
// ❌ Widget에서 다크 모드 분기
color: MediaQuery.of(context).platformBrightness == Brightness.dark
    ? Colors.grey[900]
    : Colors.white

// ✅ Theme이 자동 처리
color: Theme.of(context).colorScheme.surface
```

---

## 타이포그래피 (AppTypography)

### 텍스트 스타일 목록

| 이름 | 용도 | 기본 크기 (참고) |
|---|---|---|
| `AppTypography.displayLarge` | 히어로 텍스트, 온보딩 타이틀 | 32px |
| `AppTypography.titleLarge` | 화면 타이틀 | 22px |
| `AppTypography.titleMedium` | 섹션 제목, 카드 타이틀 | 18px |
| `AppTypography.titleSmall` | 서브 섹션 제목 | 16px |
| `AppTypography.bodyLarge` | 본문 (강조) | 16px |
| `AppTypography.bodyMedium` | 본문 (기본) | 14px |
| `AppTypography.bodySmall` | 보조 텍스트, 캡션 | 12px |
| `AppTypography.labelLarge` | 버튼 텍스트 | 14px |
| `AppTypography.labelSmall` | 태그, 뱃지, 힌트 | 11px |

### 사용 방법

```dart
// ✅ AppTypography 또는 Theme에서 가져오기
Text('카드 제목', style: AppTypography.titleMedium)
Text('설명', style: Theme.of(context).textTheme.bodyMedium)

// ❌ 하드코딩
Text('카드 제목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
```

### 스타일 커스터마이징이 필요할 때

```dart
// ✅ 기존 스타일에서 copyWith로 확장
Text(
  '강조 텍스트',
  style: AppTypography.bodyMedium.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
  ),
)

// ❌ 완전히 새로운 TextStyle 생성
Text(
  '강조 텍스트',
  style: TextStyle(fontSize: 14, color: Color(0xFF2196F3), fontWeight: FontWeight.w600),
)
```

---

## 간격 (AppSpacing)

### 간격 스케일

| 이름 | 값 (참고) | 용도 |
|---|---|---|
| `AppSpacing.xxs` | 2px | 아이콘과 텍스트 사이 미세 간격 |
| `AppSpacing.xs` | 4px | 인라인 요소 간 최소 간격 |
| `AppSpacing.sm` | 8px | 관련 요소 간 간격, 작은 패딩 |
| `AppSpacing.md` | 16px | 기본 패딩, 카드 내부 여백 |
| `AppSpacing.lg` | 24px | 섹션 간 간격 |
| `AppSpacing.xl` | 32px | 큰 섹션 간 간격 |
| `AppSpacing.xxl` | 48px | 화면 상단/하단 여백 |

### 사용 방법

```dart
// ✅ AppSpacing 상수
Padding(padding: EdgeInsets.all(AppSpacing.md))
SizedBox(height: AppSpacing.sm)
BorderRadius.circular(AppSpacing.sm)

// ❌ 하드코딩
Padding(padding: EdgeInsets.all(16))
SizedBox(height: 8)
BorderRadius.circular(8)
```

### 일관된 간격 선택 기준

- 같은 그룹 내 요소 간 → `sm` (8px)
- 다른 그룹 간 → `md` (16px) 또는 `lg` (24px)
- 화면 가장자리 → `md` (16px)
- 리스트 아이템 간 → `sm` (8px)

---

## 컴포넌트 규칙

### 공용 Widget 위치

재사용 가능한 UI 컴포넌트는 `lib/shared/widgets/`에 위치합니다.

| Widget | 파일 | 용도 |
|---|---|---|
| `AppButton` | `app_button.dart` | 기본 버튼 (Primary, Secondary, Text) |
| `LoadingView` | `loading_view.dart` | 전체 화면 로딩 |
| `ErrorView` | `error_view.dart` | 에러 표시 + 재시도 |
| `EmptyView` | `empty_view.dart` | 빈 상태 표시 |

### 새 공용 Widget 추가 기준

- 2개 이상의 feature에서 동일한 UI 패턴이 반복될 때
- 디자인 시스템에 정의된 표준 컴포넌트일 때
- 1개 feature에서만 쓰이면 해당 feature의 `widgets/`에 유지

### 버튼 사용 규칙

```dart
// ✅ 공용 버튼 사용
AppButton.primary(
  label: '저장',
  onPressed: () => viewModel.save(),
)

AppButton.secondary(
  label: '취소',
  onPressed: () => Navigator.of(context).pop(),
)

// ❌ 매번 새로 스타일링
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF2196F3),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () => viewModel.save(),
  child: Text('저장'),
)
```

---

## 아이콘

- Material Icons (`Icons.xxx`)를 기본으로 사용합니다.
- 커스텀 아이콘이 필요하면 `lib/core/theme/app_icons.dart`에 등록합니다.
- 아이콘 크기도 AppSpacing 또는 별도 상수를 사용합니다.

```dart
// ✅
Icon(Icons.delete, size: AppSpacing.lg, color: AppColors.error)

// ❌
Icon(Icons.delete, size: 24, color: Colors.red)
```

---

## 반응형 레이아웃

### 기본 원칙

- 고정 너비보다 `Expanded`, `Flexible`, `LayoutBuilder`를 선호합니다.
- 화면 크기 분기가 필요하면 `MediaQuery` 또는 `LayoutBuilder`를 사용합니다.

```dart
// ✅ 유연한 레이아웃
Row(
  children: [
    Expanded(child: CardInfoWidget(card: card)),
    SizedBox(width: AppSpacing.sm),
    IconButton(onPressed: onDelete, icon: Icon(Icons.delete)),
  ],
)

// ❌ 고정 너비
SizedBox(
  width: 300,
  child: CardInfoWidget(card: card),
)
```