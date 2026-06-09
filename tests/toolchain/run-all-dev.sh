#!/bin/bash
# Smoke test for the equa-base-dev image (T4 — local dev). Confirms the
# developer conveniences T4 adds on top of the full toolchain are present.
# The full toolchain itself is covered by run-all.sh (T3, which T4 is FROM).
# Run inside the built image:
#   docker run --rm equa-base-dev:test bash /tmp/run-all-dev.sh

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

echo "=== Developer conveniences present ==="
run_check "less"   less --version
run_check "nano"   nano --version
run_check "ps"     ps --version
run_check "unzip"  unzip -v
run_check "locale" locale

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
