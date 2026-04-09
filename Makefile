.PHONY: test coverage coverage-all coverage-open analyze check clean setup hooks verify-docs

MIN_COVERAGE := 90
COVERAGE_TITLE := s_portal_mobile Coverage
LCOV_RAW := coverage/lcov.info
LCOV_FILTERED := coverage/lcov_filtered.info
COVERAGE_HTML := coverage/html
COVERAGE_HELPER := test/coverage_helper_test.dart

# 생성 파일 제외 패턴 (한 곳에서 관리)
LCOV_EXCLUDE := \
	'*.g.dart' \
	'*.freezed.dart' \
	'*.gen.dart' \
	'*/l10n/*.dart' \
	'*/router/*.dart'

# ─── 개별 타겟 ─────────────────────────────────

## 전체 테스트 실행
test:
	flutter test

## 정적 분석
analyze:
	flutter analyze

## 커버리지 측정 + HTML 리포트 + 90% 게이트
coverage:
	flutter test --coverage --no-test-assets
	@$(MAKE) --no-print-directory _filter_and_report

## 미테스트 파일 포함한 정확한 커버리지 (CI용)
coverage-all:
	@find lib -name '*.dart' \
		! -name '*.g.dart' \
		! -name '*.freezed.dart' \
		! -name '*.gen.dart' \
		| sort \
		| sed "s|lib/|import 'package:s_portal_mobile/|;s|$$|';|" \
		> $(COVERAGE_HELPER)
	@echo "void main() {}" >> $(COVERAGE_HELPER)
	@flutter test --coverage --no-test-assets
	@rm -f $(COVERAGE_HELPER)
	@$(MAKE) --no-print-directory _filter_and_report

## 커버리지 HTML 브라우저에서 열기
coverage-open: coverage
	open $(COVERAGE_HTML)/index.html

## 분석 + 테스트 + 커버리지 한번에 (PR 전 점검용)
check: analyze coverage-all

## 커버리지 산출물 정리
clean:
	rm -rf coverage/
	rm -f $(COVERAGE_HELPER)

# ─── 내부 타겟 (직접 호출하지 마세요) ──────────

_filter_and_report:
	@lcov --remove $(LCOV_RAW) $(LCOV_EXCLUDE) \
		--ignore-errors unused \
		-o $(LCOV_FILTERED)
	@genhtml $(LCOV_FILTERED) \
		--output-directory $(COVERAGE_HTML) \
		--title "$(COVERAGE_TITLE)" \
		--quiet
	@RATE=$$(lcov --summary $(LCOV_FILTERED) 2>&1 \
		| grep 'lines' | awk '{print $$2}' | cut -d'%' -f1); \
	echo ""; \
	echo "──────────────────────────────────"; \
	echo "  Coverage: $${RATE}% (minimum: $(MIN_COVERAGE)%)"; \
	if [ $$(echo "$${RATE} < $(MIN_COVERAGE)" | bc) -eq 1 ]; then \
		echo "  ❌ 커버리지 미달"; \
		echo "──────────────────────────────────"; \
		exit 1; \
	else \
		echo "  ✅ 커버리지 통과"; \
		echo "──────────────────────────────────"; \
	fi

# ─── 셋업 타겟 ──────────────────────────────────

## Git pre-commit hook 설치
hooks:
	@mkdir -p .git/hooks
	@mkdir -p scripts
	@if [ ! -f scripts/pre-commit ]; then \
		echo "❌ scripts/pre-commit 파일이 없습니다."; \
		echo "   pre-commit 파일을 scripts/ 폴더에 넣어주세요."; \
		exit 1; \
	fi
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ pre-commit hook 설치 완료"

## 프로젝트 초기 셋업 (의존성 + 코드 생성 + hook 설치)
setup:
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	@$(MAKE) --no-print-directory hooks
	@echo ""
	@echo "✅ 프로젝트 셋업 완료"

## 문서 동기화 검증
verify-docs:
	@bash scripts/verify-docs.sh