#!/bin/bash
# Toolchain smoke test for the equa-base-ifrt image (T5 — runtime-vendor tier).
# Asserts Intel Fortran runtime libraries are present AND that the compiler
# (ifx/icx), SBCL, and Go are absent. az is inherited from the T2 base.
# Run inside the built image:
#   docker run --rm equa-base-ifrt:test bash /tmp/run-all-ifrt.sh

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 -- $2"; FAIL=$((FAIL + 1)); }

run_check() {
    local name="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        pass "$name"
    else
        fail "$name" "exit code non-zero"
    fi
}

absent_check() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" > /dev/null 2>&1; then
        fail "$name" "$cmd unexpectedly present in T5"
    else
        pass "$name"
    fi
}

echo "=== Intel Fortran runtime libraries present ==="
run_check "libifcoremt present" ls /opt/intel/oneapi/compiler/latest/lib/libifcoremt*
run_check "libifcore present"   ls /opt/intel/oneapi/compiler/latest/lib/libifcore*
run_check "libifport present"   ls /opt/intel/oneapi/compiler/latest/lib/libifport*
run_check "libimf present"      ls /opt/intel/oneapi/compiler/latest/lib/libimf*
run_check "libsvml present"     ls /opt/intel/oneapi/compiler/latest/lib/libsvml*
run_check "libintlc present"    ls /opt/intel/oneapi/compiler/latest/lib/libintlc*

echo ""
echo "=== az inherited from T2 ==="
run_check "az --version" az --version

echo ""
echo "=== Compiler and heavy toolchain must be absent ==="
absent_check "ifx absent"  ifx
absent_check "icx absent"  icx
absent_check "sbcl absent" sbcl
absent_check "go absent"   go

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
