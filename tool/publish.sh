#!/bin/bash
# Publishes all packages to pub.dev in dependency order.
# Usage: ./tool/publish.sh [--dry-run]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN="${1:-}"

ORDER=(
  "background_runtime_platform_interface"
  "background_runtime_android"
  "background_runtime_ios"
  "background_runtime_macos"
  "background_runtime_windows"
  "background_runtime_linux"
  "background_runtime_web"
  "background_runtime"
)

for pkg in "${ORDER[@]}"; do
  echo ""
  echo "=================================================="
  echo "  Publishing $pkg"
  echo "=================================================="

  if [ "$DRY_RUN" = "--dry-run" ]; then
    (cd "$ROOT/$pkg" && dart pub publish --dry-run)
  else
    (cd "$ROOT/$pkg" && dart pub publish -f)
  fi

  echo "  Done: $pkg"
done

echo ""
echo "All packages published successfully."
