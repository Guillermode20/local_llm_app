.PHONY: setup fmt analyze test test-coverage test-performance \
        build-native-host build-native-android bench pre-commit \
        doc-gen todo-scan clean

# ── Setup ────────────────────────────────────────────────────────────────

setup:
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs

# ── Quality ──────────────────────────────────────────────────────────────

fmt:
	dart format .

analyze:
	flutter analyze

pre-commit:
	./scripts/pre-commit.sh

# ── Testing ──────────────────────────────────────────────────────────────

test:
	flutter test --reporter expanded

test-coverage:
	flutter test --coverage --coverage-package=local_llm_app
	@echo "Coverage report generated at coverage/lcov.info"

test-performance:
	flutter test --reporter expanded 2>&1 | tail -5

# ── Build ────────────────────────────────────────────────────────────────

build-native-host:
	@echo "Native host build is not wired yet."

build-native-android:
	@echo "Native Android build is not wired yet."

# ── Tooling ──────────────────────────────────────────────────────────────

bench:
	@echo "Benchmark target is not wired yet."

doc-gen:
	dart doc .

todo-scan:
	@echo "--- TODO / FIXME scan ---"
	@rg -n "TODO|FIXME|HACK|XXX" --type dart lib/ test/ || true

clean:
	flutter clean
	rm -rf coverage/ doc/api/