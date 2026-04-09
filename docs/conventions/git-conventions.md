# Git Conventions — Git 컨벤션 가이드

## 이 문서의 목적

CLAUDE.md에 명시된 Git 규칙의 **상세 예시, scope 목록, 브랜치 전략**을 다룹니다.
핵심 규칙 자체는 CLAUDE.md를 참조하세요.

---

## 커밋 메시지 형식

```
<type>(<scope>): <한국어 메시지>

<한국어 본문 — 필요한 경우에만>
```

- `type`과 `scope`는 영어
- 메시지와 본문은 한국어
- 한국어는 명사형 종결 ("`~추가`", "`~수정`", "`~제거`")

---

## Type 목록

| type | 용도 | 예시 |
|---|---|---|
| `feat` | 새 기능 추가 | `feat(card): 카드 상세 화면 추가` |
| `fix` | 버그 수정 | `fix(auth): 토큰 만료 시 자동 갱신 실패 수정` |
| `refactor` | 동작 변경 없는 코드 개선 | `refactor(card): UseCase 단일 책임 분리` |
| `docs` | 문서 변경 | `docs(architecture): 레이어 규칙 업데이트` |
| `test` | 테스트 추가/수정 | `test(card): GetCardsUseCase 유닛 테스트 추가` |
| `style` | 포맷팅, 세미콜론 등 | `style(core): dart format 적용` |
| `perf` | 성능 개선 | `perf(card): 카드 목록 페이지네이션 적용` |
| `build` | 빌드 설정 변경 | `build(android): minSdk 24로 상향` |
| `ci` | CI/CD 설정 변경 | `ci(github): coverage 게이트 90% 적용` |
| `chore` | 기타 잡일 | `chore(deps): freezed 2.5.0 업데이트` |
| `revert` | 이전 커밋 되돌리기 | `revert(auth): 토큰 갱신 로직 롤백` |

### type 선택 기준

- 사용자에게 보이는 변화 → `feat` 또는 `fix`
- 사용자에게 안 보이는 내부 변화 → `refactor`, `perf`, `style`
- 코드 외 변화 → `docs`, `build`, `ci`, `chore`, `test`

---

## Scope 목록

### feature scope

`lib/features/` 디렉토리 이름과 일치시킵니다.

| scope | 대상 |
|---|---|
| `auth` | 인증, 로그인, 회원가입 |
| `card` | 카드 CRUD |
| `settings` | 설정 화면 |
| *(feature 추가 시 여기에 추가)* | |

### 공용 scope

| scope | 대상 |
|---|---|
| `core` | `lib/core/` 공용 인프라 |
| `shared` | `lib/shared/` 공용 위젯, Provider |
| `network` | Dio 클라이언트, 인터셉터 |
| `router` | GoRouter 설정 |
| `theme` | 테마, 색상, 타이포, 간격 |
| `l10n` | 다국어 |
| `deps` | 패키지 의존성 변경 |
| `config` | 프로젝트 설정 (analysis_options 등) |

### scope 선택 규칙

- 변경 파일이 하나의 feature 안에 있으면 → 해당 feature scope
- `core/` 변경이면 → 하위 모듈 scope (`network`, `router`, `theme` 등)
- 여러 feature에 걸치면 → 가장 핵심적인 scope, 또는 scope 없이 `refactor: ...`

---

## 한국어 작성 스타일

### 명사형 종결 사용

```
✅ 로그인 검증 추가
✅ 잘못된 요청 전달 방지
✅ 필드별 validator 추가
✅ 유효하지 않은 경우 제출 차단 로직 적용

❌ 로그인 검증을 추가했다
❌ 잘못된 요청이 API까지 전달되는 것을 막기 위해서다
❌ 필드별 validator를 추가했다
```

### 메시지 길이

- subject: 50자 이내 권장
- 길어지면 본문에서 보충

---

## 커밋 본문 (Body)

### 본문이 필요한 경우

- 로직 변경이 포함된 경우
- 변경 단계가 여러 개인 경우
- 변경 이유가 코드만으로 명확하지 않은 경우
- 기존 동작이 바뀌는 경우 (breaking change)

### 본문 형식

```
What:
변경 내용 요약

Why:
변경 이유

How:
구현 방법 (필요한 경우)
```

### 본문 예시

```bash
git commit -m "feat(auth): 로그인 폼 검증 추가" -m "What:
로그인 폼 입력값 검증 추가

Why:
잘못된 요청의 API 전달 방지

How:
필드별 validator 추가
유효하지 않은 경우 제출 차단 로직 적용"
```

### 본문이 필요 없는 경우

```bash
git commit -m "style(core): dart format 적용"
git commit -m "docs(readme): 설치 가이드 추가"
git commit -m "test(card): CardMapper 유닛 테스트 추가"
```

---

## 브랜치 전략

### 브랜치 네이밍

```
feature/{scope}/{간단한-설명}
fix/{scope}/{간단한-설명}
refactor/{scope}/{간단한-설명}
```

예시:

```
feature/auth/login-form-validation
fix/card/list-sorting-error
refactor/core/error-handling-result-type
```

### 브랜치 규칙

- 새 작업은 `main`에서 feature 브랜치를 생성합니다.
- `main`에 직접 커밋하지 않습니다.
- PR(Pull Request)을 통해 병합합니다.
- 병합 전 `flutter analyze` + `flutter test`가 통과해야 합니다.

---

## 커밋 단위 (Atomic Commits)

### 원칙: 하나의 커밋 = 하나의 scope

```bash
# ✅ scope별로 분리
git commit -m "feat(card): 카드 Entity 및 Repository 인터페이스 정의"
git commit -m "feat(card): 카드 DataSource 및 Repository 구현체 추가"
git commit -m "feat(card): 카드 목록 ViewModel 및 Screen 추가"

# ❌ 여러 scope를 하나에 몰아넣기
git commit -m "feat: 카드 기능 전체 추가"
```

### 분리 기준

| 변경 내용 | 커밋 수 |
|---|---|
| domain 레이어 (Entity, Repository 인터페이스, UseCase) | 1 커밋 |
| data 레이어 (Model, Mapper, DataSource, Repository 구현체) | 1 커밋 |
| presentation 레이어 (ViewModel, Screen, Widget) | 1 커밋 |
| 테스트 | 해당 레이어 커밋에 포함하거나 별도 1 커밋 |

---

## 생성 파일 처리

- `.g.dart`, `.freezed.dart` 생성 파일은 커밋에 포함합니다.
- `build_runner` 실행 후 생성된 파일을 빠뜨리지 마세요.
- `.gitignore`에 생성 파일을 넣지 마세요.

```bash
# freezed/riverpod 관련 소스 변경 후
dart run build_runner build --delete-conflicting-outputs

# 생성 파일도 함께 stage
git add lib/features/card/domain/entities/card_entity.dart
git add lib/features/card/domain/entities/card_entity.freezed.dart
git add lib/features/card/domain/entities/card_entity.g.dart
```

---

## 좋은/나쁜 커밋 메시지 비교

| ❌ 나쁜 예 | ✅ 좋은 예 |
|---|---|
| `fix: 버그 수정` | `fix(card): 카드 목록 정렬 기준 누락 수정` |
| `feat: 기능 추가` | `feat(auth): 소셜 로그인 카카오 연동 추가` |
| `update code` | `refactor(card): Repository 에러 처리 Result 패턴 적용` |
| `wip` | `feat(card): 카드 생성 폼 UI 구현 (API 연동 전)` |
| `feat(card): 카드 상세 화면을 추가했습니다` | `feat(card): 카드 상세 화면 추가` |