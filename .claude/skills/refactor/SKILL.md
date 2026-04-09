---
name: refactor
description: >
  Flutter 코드베이스에서 리팩토링 대상을 탐지하고 표 형태로 제안합니다.
  자동 수정하지 않고, 사용자가 승인한 항목만 수정합니다.
  수정 후 커밋은 refactor(scope): 형식으로 자동 생성합니다.

  다음 중 하나라도 해당하면 반드시 이 스킬을 사용하세요:
  - "리팩토링 대상 찾아줘", "리팩토링해줘", "코드 정리", "품질 스캔" 요청 시
  - "/refactor" 커맨드 입력 시
  - "미사용 코드 찾아줘", "TODO 정리", "테스트 없는 파일 찾아줘" 요청 시
  - 코드베이스 전반적 품질 개선이 필요할 때
---

# refactor 스킬

## 목적

코드베이스 전체를 스캔해 리팩토링이 필요한 곳을 찾아내고,
사용자가 직접 확인·승인한 항목만 수정합니다.
스캔은 항상 읽기 전용으로 진행하며, 사용자 승인 없이 파일을 변경하지 않습니다.

---

## 2단계 실행 흐름

### Phase 1: 스캔 & 리포트

`lib/` 및 `test/` 디렉토리를 대상으로 아래 5가지 항목을 검사하고 표로 정리합니다.

### Phase 2: 승인 & 수정

사용자가 번호로 승인한 항목만 수정하고, `refactor(scope):` 커밋을 생성합니다.

---

## 탐지 항목

### 1. 200줄 초과 파일

`lib/` 아래 `.dart` 파일 중 줄 수가 200을 초과하는 파일.
생성 파일(`.g.dart`, `.freezed.dart`)은 제외.

**제안 조치**: 200줄 초과 원인에 따라
- Screen/Widget 파일 → 하위 Widget으로 분리
- ViewModel 파일 → State 클래스 분리 검토
- Repository 파일 → 메서드 단위 UseCase 추출 검토

### 2. 반복되는 코드 패턴 (3곳 이상)

동일하거나 매우 유사한 코드 블록이 3개 이상의 서로 다른 파일에 등장하는 경우.
판단 기준: 5줄 이상의 동일한 로직 블록이 3곳 이상 반복.

흔한 사례:
- try-catch + AppLogger.error 패턴이 여러 Repository에서 동일하게 반복
- AsyncValue.when 분기 코드가 여러 Screen에서 동일하게 반복

**제안 조치**: `lib/shared/` 또는 `lib/core/` 에 공통 헬퍼/믹스인으로 추출

### 3. 사용되지 않는 export

`lib/` 아래 파일에서 `export` 키워드로 노출되거나,
public 함수/클래스인데 다른 파일 어디서도 import되지 않는 경우.

탐지 방법:
- 파일에서 public 클래스/함수 이름 목록 추출
- 해당 이름이 다른 `.dart` 파일에서 import되는지 전체 검색
- 완전히 미참조면 "미사용" 후보로 분류

**주의**: entrypoint(`main.dart`, `app.dart`)에서 간접 참조되는 경우는 제외.

**제안 조치**: 미사용 코드 제거 또는 `_` 접두사로 internal 표시

### 4. 해결된 TODO/FIXME

코드 내 `// TODO:` 또는 `// FIXME:` 주석 탐지.
단, 아래는 제외:
- `// TODO(이름):` 형식으로 담당자가 지정된 경우 → 의도적 미완성일 수 있음
- 생성 파일

탐지 후 해당 코드를 실제로 읽어 주석이 이미 해결됐는지 판단합니다.
- 주석이 가리키는 기능이 이미 구현돼 있음 → "해결된 TODO" 로 분류
- 아직 구현이 없음 → 리포트에서 제외 (아직 해야 할 일)

**제안 조치**: 주석 제거

### 5. 테스트 파일 없는 UseCase

`lib/features/*/domain/usecases/` 아래 `*_usecase.dart` 파일 목록 수집.
각각 `test/features/*/domain/usecases/*_usecase_test.dart` 가 존재하는지 확인.
없으면 "테스트 누락" 으로 분류.

**제안 조치**: 해당 UseCase 테스트 파일 생성 (보일러플레이트 자동 생성 가능)

---

## 리포트 형식

```
## 리팩토링 스캔 결과

**스캔 범위**: lib/ + test/  
**탐지 건수**: N건

| # | 파일 | 문제 유형 | 세부 내용 | 제안 조치 |
|---|------|----------|----------|---------|
| 1 | lib/features/card/presentation/screens/card_list_screen.dart | 200줄 초과 | 280줄 | 하위 Widget 분리 권장 |
| 2 | lib/core/utils/logger.dart | 미사용 export | `formatLog()` 미참조 | 제거 권장 |
| 3 | lib/features/card/data/repositories/card_repository_impl.dart | 반복 패턴 | try-catch 블록 3곳 반복 | 공통 헬퍼 추출 |
| 4 | lib/features/card/domain/usecases/get_cards_usecase.dart | TODO 주석 | line 12: // TODO: 에러 처리 추가 (이미 구현됨) | 주석 제거 |
| 5 | lib/features/profile/domain/usecases/get_profile_usecase.dart | 테스트 누락 | 테스트 파일 없음 | 테스트 파일 생성 |

---

수정할 항목 번호를 알려주세요 (예: "1, 3, 5" 또는 "전체" 또는 "건너뜀").
```

탐지 건수가 0이면:

```
## 리팩토링 스캔 결과

✅ 스캔 완료 — 리팩토링 대상이 발견되지 않았습니다.
```

---

## Phase 2: 수정 & 커밋

사용자가 번호를 지정하면:

1. 지정된 항목만 수정 (나머지 건드리지 않음)
2. 수정 전 변경 내용을 요약해 다시 확인 요청
3. 승인 후 수정 실행
4. 커밋 생성: `refactor(scope): 설명`
   - scope는 수정된 파일의 feature 이름 사용 (예: `card`, `core`)
   - 여러 feature가 섞이면 scope에 `cleanup` 사용

### 커밋 메시지 예시

```
refactor(card): card_list_screen 하위 Widget 분리 (280줄 → 3개 파일)
refactor(core): 미사용 formatLog() 제거
refactor(cleanup): 해결된 TODO 주석 3건 제거
```

---

## 주의사항

- 스캔은 읽기 전용이며 어떤 파일도 수정하지 않습니다.
- 사용자가 "전체" 또는 특정 번호를 명시하기 전까지 수정하지 않습니다.
- "미사용 export" 탐지는 false positive가 있을 수 있습니다. 확신하기 어려운 경우 "확인 필요"로 표시합니다.
- 반복 패턴 탐지는 기계적 일치가 아니라 의미적 유사성 기준입니다. 의심스러우면 해당 코드를 직접 읽어 판단합니다.
- `pubspec.yaml` 수정이 필요한 경우(새 패키지 추가 등) 자동 수정하지 않고 사용자에게 제안만 합니다.
