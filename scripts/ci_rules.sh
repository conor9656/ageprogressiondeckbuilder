#!/usr/bin/env bash
# Canonical rules CI entry — Godot headless is the only rules gate.
# Python under sim/ is a research oracle and is NOT run here.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Ages rules CI (Godot canonical) ==="
if ! command -v godot4 >/dev/null 2>&1; then
  echo "godot4 missing — installing…"
  bash "$ROOT/scripts/install_godot.sh"
fi
godot4 --version

echo "=== Running headless suite ==="
# Capture output so we can assert the success token (set -o pipefail keeps failures).
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
set +e
bash "$ROOT/scripts/run_game_tests.sh" 2>&1 | tee "$OUT"
CODE=${PIPESTATUS[0]}
set -e
if [[ "$CODE" -ne 0 ]]; then
  echo "AGES_RULES_CI_FAIL exit=$CODE"
  exit "$CODE"
fi
if ! grep -q 'AGES_TESTS_OK failed=0' "$OUT"; then
  echo "AGES_RULES_CI_FAIL missing AGES_TESTS_OK token"
  exit 1
fi
echo "AGES_RULES_CANONICAL ok — Godot headless is the rules source of truth"
exit 0
