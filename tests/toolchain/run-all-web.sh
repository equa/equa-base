#!/bin/bash
# Smoke test for the equa-base-web image (T6 — web checks tier). Confirms
# Playwright's headless Chromium shell starts, so a missing library fails here,
# not in a consumer's Playwright tests. T1's tools are covered by run-all-ci.sh.
# Run inside the built image:
#   docker run --rm equa-base-web:test bash /tmp/run-all-web.sh

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }

run_check() {
    local name="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        pass "$name"
    else
        fail "$name" "exit code non-zero"
    fi
}

headless_shell_version() {
    local bins=("$PLAYWRIGHT_BROWSERS_PATH"/chromium_headless_shell-*/chrome-*/chrome-headless-shell)
    "${bins[0]}" --version
}

echo "=== Headless Chromium present ==="
run_check "node --version"          node --version
run_check "chromium headless shell" headless_shell_version

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
