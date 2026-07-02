SHELL := /bin/bash
PACKAGES := background_runtime background_runtime_platform_interface background_runtime_android background_runtime_ios background_runtime_macos background_runtime_windows background_runtime_linux background_runtime_web
EXAMPLE := example

.PHONY: all get analyze test test-all clean clean-all publish publish-dry-run help

all: get analyze test

# --- Dependency management ---

get:
	dart pub get

get-all:
	@for pkg in $(PACKAGES) $(EXAMPLE); do \
		echo "==> $$pkg: dart pub get"; \
		(cd $$pkg && dart pub get) || exit 1; \
	done

# --- Analysis ---

analyze:
	dart analyze

analyze-all:
	@for pkg in $(PACKAGES) $(EXAMPLE); do \
		echo "==> $$pkg: dart analyze"; \
		(cd $$pkg && dart analyze) || exit 1; \
	done

# --- Testing ---

.PHONY: test test-platform-interface test-app

test: test-platform-interface test-app

test-platform-interface:
	cd background_runtime_platform_interface && flutter test

test-app:
	cd background_runtime && flutter test

test-all:
	@for pkg in $(PACKAGES) $(EXAMPLE); do \
		if [ -d "$$pkg/test" ]; then \
			echo "==> $$pkg: flutter test"; \
			(cd $$pkg && flutter test) || exit 1; \
		fi; \
	done

# --- Cleaning ---

clean:
	@for pkg in $(PACKAGES) $(EXAMPLE); do \
		echo "==> $$pkg: cleaning"; \
		(cd $$pkg && rm -rf .dart_tool build pubspec.lock) 2>/dev/null || true; \
	done
	rm -rf .dart_tool pubspec.lock

clean-all: clean
	@for pkg in $(PACKAGES) $(EXAMPLE); do \
		echo "==> $$pkg: flutter clean"; \
		(cd $$pkg && flutter clean) 2>/dev/null || true; \
	done

# --- Publishing ---

publish-dry-run:
	@echo "=== Dry-run publish (dependency order) ==="
	cd background_runtime_platform_interface && dart pub publish --dry-run
	cd background_runtime_android && dart pub publish --dry-run
	cd background_runtime_ios && dart pub publish --dry-run
	cd background_runtime_macos && dart pub publish --dry-run
	cd background_runtime_windows && dart pub publish --dry-run
	cd background_runtime_linux && dart pub publish --dry-run
	cd background_runtime_web && dart pub publish --dry-run
	cd background_runtime && dart pub publish --dry-run

publish:
	@echo "=== Publishing (dependency order) ==="
	cd background_runtime_platform_interface && dart pub publish -f
	cd background_runtime_android && dart pub publish -f
	cd background_runtime_ios && dart pub publish -f
	cd background_runtime_macos && dart pub publish -f
	cd background_runtime_windows && dart pub publish -f
	cd background_runtime_linux && dart pub publish -f
	cd background_runtime_web && dart pub publish -f
	cd background_runtime && dart pub publish -f

# --- Utilities ---

outdated:
	@for pkg in $(PACKAGES) $(EXAMPLE); do \
		echo "=== $$pkg ==="; \
		(cd $$pkg && dart pub outdated) || true; \
	done

upgrade:
	dart pub upgrade

# --- Help ---

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Core:"
	@echo "  all            Run get, analyze, test"
	@echo "  get            Run dart pub get (workspace)"
	@echo "  analyze        Run dart analyze (workspace)"
	@echo "  test           Run tests for platform_interface + app package"
	@echo "  clean          Remove build artifacts"
	@echo ""
	@echo "Publishing:"
	@echo "  publish-dry-run  Dry-run publish all packages in order"
	@echo "  publish          Publish all packages to pub.dev"
	@echo ""
	@echo "Per-package:"
	@echo "  test-platform-interface  Test platform_interface only"
	@echo "  test-app                 Test app-facing package only"
	@echo ""
	@echo "Utilities:"
	@echo "  outdated       Check outdated deps for all packages"
	@echo "  upgrade        Upgrade workspace dependencies"
