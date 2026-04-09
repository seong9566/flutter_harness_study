# Flutter Harness Engineering Study

AI 에이전트가 실수할 수 없는 환경을 만드는 **하네스 엔지니어링** 실습 프로젝트입니다.

> AI 에이전트가 실수했을 때, 프롬프트를 고치지 않고. harness를 고치세요.

---

## 프로젝트 구조

```
.
├── .claude/                         # Claude Code 설정
│   ├── settings.json                # Hooks (결정론적 게이트)
│   ├── agents/                      # 검증 전문 에이전트
│   │   ├── arch-validator.md        # 레이어 의존성 위반 검사
│   │   ├── security-reviewer.md     # 보안 취약점 탐지
│   │   └── quality-scanner.md       # 코드 품질 스캔
│   └── skills/                      # 자동화 워크플로우
│       ├── git-commit/              # scope별 분리 커밋
│       ├── flutter-architecture/    # Clean Architecture 패턴
│       ├── code-review/             # 변경사항 아키텍처 리뷰
│       ├── new-feature/             # feature 모듈 자동 생성
│       ├── refactor/                # 리팩토링 대상 탐지
│       └── quality-scan/            # 품질 스캔 + 피드백 루프
│
├── docs/                            # 상세 참조 문서
│   ├── architecture/
│   │   ├── layer-rules.md           # 레이어 의존성 규칙 (배경, 이유)
│   │   ├── directory-structure.md   # 디렉토리 구조 + 새 feature 절차
│   │   ├── patterns.md              # 모든 코드 예시 (단일 소스)
│   │   ├── riverpod-patterns.md     # Riverpod 생명주기, Provider 구성
│   │   └── design-system.md         # 색상, 타이포, 간격, 컴포넌트
│   ├── conventions/
│   │   ├── dart-style.md            # 네이밍, 문서화, 타입 안전성
│   │   ├── widget-patterns.md       # Widget 분리 기준, build() 규칙
│   │   ├── testing-guide.md         # mocktail, 레이어별 테스트 전략
│   │   └── git-conventions.md       # 커밋 메시지, 브랜치 전략
│   └── onboarding.md               # 프로젝트 셋업 가이드
│
├── .github/workflows/
│   ├── ci.yml                       # PR 시 자동 검증 (analyze + test + coverage)
│   └── auto-fix.yml                 # CI 실패 시 자동 수정 + PR 코멘트
│
├── scripts/
│   ├── pre-commit                   # 로컬 커밋 전 자동 검증
│   └── verify-docs.sh               # docs/와 코드 구조 동기화 검증
│
├── CLAUDE.md                        # AI 행동 규칙 (핵심)
└── Makefile                         # 빌드, 테스트, 셋업 자동화
```

---

## 하네스 4가지 기둥

### 기둥 1: 컨텍스트 파일

AI가 참조하는 규칙과 문서입니다.

| 파일 | 역할 |
|---|---|
| `CLAUDE.md` | 핵심 규칙 — AI가 매 턴마다 읽는 "신호등" |
| `docs/architecture/` | 아키텍처 배경, 이유, 코드 패턴 |
| `docs/conventions/` | 코딩/테스트/Git 컨벤션 |
| `docs/onboarding.md` | 프로젝트 셋업 가이드 |

**원칙:** CLAUDE.md는 짧은 규칙만, docs/는 상세 설명과 코드 예시.

### 기둥 2: Hooks (결정론적 게이트)

`.claude/settings.json`에 정의된 자동 실행 규칙입니다. CLAUDE.md가 "부탁"이라면, Hooks는 "물리적 차단"입니다.

| Hook | 역할 |
|---|---|
| 수정 금지 파일 차단 | `pubspec.yaml`, `.env*` 수정 시 block |
| 위험 명령어 차단 | `rm -rf`, `--force push` 등 block |
| 패키지 설치 차단 | `flutter pub add` 감지 시 block |
| 커밋 전 자동 검증 | `git commit` → analyze + test 실행, 실패 시 block |
| 코드 자동 포맷 | 파일 저장 후 `dart format` 자동 실행 |
| 작업 종료 전 테스트 | 종료 시 `flutter test`, 실패 시 계속 작업 |
| build_runner 자동 실행 | freezed/riverpod 소스 수정 시 자동 트리거 |
| 커밋 메시지 형식 검증 | `type(scope): 설명` 불일치 시 block |

### 기둥 3: Skills + Agents

| 종류 | 이름 | 역할 |
|---|---|---|
| **Skill** | `/git-commit` | scope별 분리 커밋 자동 생성 |
| **Skill** | `/new-feature` | 3레이어 feature 모듈 보일러플레이트 생성 |
| **Skill** | `/code-review` | 변경사항을 프로젝트 규칙 기준으로 리뷰 |
| **Skill** | `/refactor` | 리팩토링 대상 탐지 + 제안 |
| **Skill** | `/quality-scan` | 품질 스캔 + CLAUDE.md 규칙 추가 제안 |
| **Agent** | `arch-validator` | 레이어 의존성 위반 검사 (Sonnet) |
| **Agent** | `security-reviewer` | 보안 취약점 탐지 (Sonnet) |
| **Agent** | `quality-scanner` | 코드 품질 스캔 (Haiku, 빠르고 저렴) |

**Skill vs Agent:** Skill은 작업을 실행하고, Agent는 검증만 합니다 (쓰기 도구 없음).

### 기둥 4: 피드백 루프

AI가 실수할 때마다 하네스가 강화되는 구조입니다.

```
AI 실수 발견
  → CLAUDE.md "자주 하는 실수" 섹션에 규칙 추가
    → 같은 실수 3회 반복 시 Hook으로 승격
      → 마구가 점점 더 정교해짐
```

---

## 시작하기

### 초기 셋업

```bash
# 프로젝트 클론 후
make setup
# → flutter pub get + build_runner + pre-commit hook 설치
```

### 주요 명령어

```bash
# 테스트
make test

# 정적 분석
make analyze

# 커버리지 (90% 게이트)
make coverage

# PR 전 전체 점검 (analyze + coverage)
make check

# 문서 동기화 검증
make verify-docs

# 커버리지 HTML 리포트 열기
make coverage-open
```

### Claude Code에서 사용

```bash
# 새 feature 생성
/new-feature card

# 코드 리뷰
/code-review

# 커밋
/git-commit

# 품질 스캔
/quality-scan

# 리팩토링 대상 탐색
/refactor
```

---

## 문서 역할 분리 원칙

```
CLAUDE.md        →  "~하지 마세요" (신호등, 매번 읽음)
docs/            →  "왜 그런지, 어떻게 하는지" (필요할 때 참조)
Hooks            →  "물리적으로 못 하게" (자동 차단)
Skills           →  "이렇게 해" (작업 자동화)
Agents           →  "제대로 했는지 확인" (검증 전문)
```

---

## 참고 자료

- [OpenAI — Harness Engineering (2026.02)](https://openai.com/index/harness-engineering/)
- [Martin Fowler — Harness Engineering for Coding Agent Users](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)
- [Anthropic — Effective Harnesses for Long-Running Agents](https://docs.anthropic.com)