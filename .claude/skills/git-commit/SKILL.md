---
name: git-commit
description: >
  로컬 변경사항을 분석해 scope별로 분리된 Conventional Commits을 생성합니다.
  git status로 파일을 수집하고 feature/모듈 기준으로 그룹핑한 뒤,
  type(scope): 한국어 메시지 형식으로 커밋 계획을 제시하고 승인 후 실행합니다.

  다음 중 하나라도 해당하면 반드시 이 스킬을 사용하세요:
  - "커밋해줘", "변경사항 커밋", "커밋 만들어줘" 요청 시
  - "/git-commit" 커맨드 입력 시
  - "git commit" 언급 시 (단, 이미 메시지가 명시된 경우는 제외)
  - 여러 파일이 변경됐고 scope별 분리 커밋이 필요한 상황
---

# git-commit 스킬

## 목적

변경된 파일을 scope 단위로 묶어 의미 있는 커밋 히스토리를 만듭니다.
커밋 계획을 먼저 보여주고, 사용자 승인 후 실행합니다.
커밋 후 `git log -n 5`로 히스토리를 확인합니다.

---

## 실행 순서

1. **변경 파일 수집** — `git status --short` 실행
2. **그룹핑** — 파일 경로 기준으로 scope 분류
3. **커밋 계획 제시** — 각 그룹의 type/scope/메시지 초안 표시
4. **승인 대기** — 사용자 확인 후 진행
5. **scope별 순서 커밋** — `git add` → `git commit` 반복
6. **히스토리 확인** — `git log -n 5`

---

## Scope 분류 규칙

파일 경로로 scope를 결정합니다:

| 파일 경로 패턴 | scope |
|--------------|-------|
| `lib/features/{name}/...` | `{name}` (예: `card`, `auth`) |
| `lib/core/network/...` | `network` |
| `lib/core/router/...` | `router` |
| `lib/core/theme/...` | `theme` |
| `lib/core/l10n/...` | `l10n` |
| `lib/core/...` (그 외) | `core` |
| `lib/shared/...` | `shared` |
| `test/features/{name}/...` | `{name}` (소스와 동일 scope) |
| `docs/...` | 문서가 다루는 영역 scope |
| `pubspec.yaml`, `analysis_options.yaml` 등 | `config` 또는 `deps` |
| `.github/...` | `ci` |

**생성 파일 처리**: `.g.dart`, `.freezed.dart`는 원본 소스 파일과 같은 그룹에 포함합니다. 별도 커밋을 만들지 않습니다.

**같은 feature의 여러 레이어**: 변경 규모에 따라 판단합니다.
- 레이어가 명확히 분리된 대규모 작업 → 레이어별 커밋 (domain/data/presentation)
- 소규모 수정 → feature scope로 묶어 1 커밋

---

## Type 선택 기준

| 변경 성격 | type |
|----------|------|
| 새 기능, 새 화면, 새 파일 추가 | `feat` |
| 버그 수정 | `fix` |
| 동작 변경 없는 코드 개선 | `refactor` |
| 테스트 파일 추가/수정 | `test` |
| 문서 변경 | `docs` |
| 포맷팅, lint 수정 | `style` |
| 성능 개선 | `perf` |
| 패키지 업데이트, 설정 변경 | `chore` |
| 빌드 설정 (android/, ios/) | `build` |
| CI/CD 설정 | `ci` |

---

## 커밋 메시지 형식

```
type(scope): 한국어 메시지

What:
변경 내용 요약

Why:
변경 이유

How:
구현 방법 (선택)
```

- **type, scope**: 영어 소문자
- **메시지, 본문**: 한국어 명사형 종결 ("추가", "수정", "제거", "적용")
- **subject**: 50자 이내 권장
- **본문 생략 가능한 경우**: `style`, `docs`, `test`, `chore` 등 이유가 자명할 때

**좋은 메시지 예시:**
```
feat(auth): 로그인 폼 필드 검증 추가
fix(card): 카드 목록 정렬 기준 누락 수정
refactor(core): 에러 처리 Result 패턴 적용
test(card): GetCardsUseCase 유닛 테스트 추가
docs(architecture): 레이어 의존성 규칙 업데이트
```

---

## 커밋 계획 표시 형식

실행 전 다음 형식으로 계획을 보여줍니다:

```
## 커밋 계획

변경 파일 N개 → N개 커밋

---

**커밋 1** — feat(auth)
파일:
  - lib/features/auth/domain/entities/user_entity.dart
  - lib/features/auth/domain/entities/user_entity.freezed.dart
메시지: feat(auth): 사용자 Entity 정의
본문: 없음

---

**커밋 2** — feat(card)
파일:
  - lib/features/card/presentation/screens/card_list_screen.dart
  - lib/features/card/presentation/view_models/card_list_view_model.dart
메시지: feat(card): 카드 목록 화면 및 ViewModel 추가
본문:
  What: 카드 목록 조회 화면 구현
  Why: 사용자 카드 관리 기능 진입점 필요
  How: ConsumerWidget + AsyncValue.when 패턴 적용

---

진행할까요? (수정이 필요하면 알려주세요)
```

---

## 커밋 실행

승인 후 각 그룹을 순서대로 처리합니다:

```bash
# 해당 그룹 파일만 stage
git add <파일1> <파일2> ...

# 본문 없는 경우
git commit -m "type(scope): 메시지"

# 본문 있는 경우 (heredoc 사용)
git commit -m "type(scope): 메시지" -m "What:
내용

Why:
이유"
```

모든 커밋 완료 후:
```bash
git log -n 5 --oneline
```

---

## 주의사항

- 계획 표시 후 반드시 사용자 승인을 받고 실행합니다.
- `git add -A` 또는 `git add .`를 사용하지 않습니다. 파일을 명시적으로 지정합니다.
- untracked 파일 중 `.env`, `firebase_options.dart` 같은 민감 파일이 있으면 커밋 계획에서 제외하고 사용자에게 경고합니다.
- `--no-verify` 플래그를 사용하지 않습니다. hook이 실패하면 원인을 파악합니다.
- 이미 staged된 파일이 있으면 먼저 상태를 보여주고 이미 staged된 것을 포함할지 물어봅니다.
- `freezed`/`riverpod` 관련 소스가 변경됐는데 생성 파일(`.g.dart`, `.freezed.dart`)이 없으면 `dart run build_runner build --delete-conflicting-outputs` 실행 여부를 먼저 물어봅니다.
