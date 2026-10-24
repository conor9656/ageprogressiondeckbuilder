#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if ! command -v godot4 >/dev/null 2>&1; then
  bash "$ROOT/scripts/install_godot.sh"
fi
exec godot4 --headless --path "$ROOT/game" -s res://tests/run_tests.gd
