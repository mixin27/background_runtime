#!/bin/bash
# Bumps the version of all packages and updates inter-package dependencies.
# Usage: ./tool/version.sh <new-version>
# Example: ./tool/version.sh 0.2.0

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <new-version>"
  echo "Example: $0 0.2.0"
  exit 1
fi

NEW_VERSION="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PACKAGES=(
  "background_runtime"
  "background_runtime_platform_interface"
  "background_runtime_android"
  "background_runtime_ios"
  "background_runtime_macos"
  "background_runtime_windows"
  "background_runtime_linux"
  "background_runtime_web"
)

echo "Bumping all packages to version $NEW_VERSION"

for pkg in "${PACKAGES[@]}"; do
  PUBSPEC="$ROOT/$pkg/pubspec.yaml"
  if [ -f "$PUBSPEC" ]; then
    # Update version line
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"

    # Update inter-package dependency constraints (e.g. ^0.1.0 -> ^0.2.0)
    OLD_VERSION=$(echo "$NEW_VERSION" | sed 's/\.[0-9]*$//')
    sed -i '' "s/background_runtime_platform_interface: \^.*\$/background_runtime_platform_interface: ^$OLD_VERSION/" "$PUBSPEC"
    sed -i '' "s/background_runtime_android: \^.*\$/background_runtime_android: ^$OLD_VERSION/" "$PUBSPEC"
    sed -i '' "s/background_runtime_ios: \^.*\$/background_runtime_ios: ^$OLD_VERSION/" "$PUBSPEC"
    sed -i '' "s/background_runtime_macos: \^.*\$/background_runtime_macos: ^$OLD_VERSION/" "$PUBSPEC"
    sed -i '' "s/background_runtime_windows: \^.*\$/background_runtime_windows: ^$OLD_VERSION/" "$PUBSPEC"
    sed -i '' "s/background_runtime_linux: \^.*\$/background_runtime_linux: ^$OLD_VERSION/" "$PUBSPEC"
    sed -i '' "s/background_runtime_web: \^.*\$/background_runtime_web: ^$OLD_VERSION/" "$PUBSPEC"
    sed -i '' "s/background_runtime: \^.*\$/background_runtime: ^$OLD_VERSION/" "$PUBSPEC"

    echo "  Updated: $pkg -> $NEW_VERSION (deps ^$OLD_VERSION)"
  fi
done

echo ""
echo "Version bumped to $NEW_VERSION."
echo "Run 'dart pub get' to update the lockfile."
