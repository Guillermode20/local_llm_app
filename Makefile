.PHONY: fmt analyze test build-native-host build-native-android bench

fmt:
	dart format .

analyze:
	flutter analyze

test:
	flutter test

build-native-host:
	@echo "Native host build is not wired yet."

build-native-android:
	@echo "Native Android build is not wired yet."

bench:
	@echo "Benchmark target is not wired yet."