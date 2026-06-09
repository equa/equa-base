#!/bin/bash
# Toolchain smoke test for the equa-base-lite image (non-compile CI tier).
# Asserts every lite tool resolves AND that the heavy toolchain (oneAPI / SBCL /
# Go) is absent — the lite tier must not silently inherit compilers.
# Run inside the built image:
#   docker run --rm equa-base-lite:test bash /tmp/run-all-lite.sh

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

# Asserts a command is NOT on PATH (the heavy toolchain must stay in `full`).
absent_check() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" > /dev/null 2>&1; then
        fail "$name" "$cmd unexpectedly present in lite"
    else
        pass "$name"
    fi
}

echo "=== Tool version checks ==="
run_check "python3 --version"           python3 --version
run_check "node --version"              node --version
run_check "uv --version"                uv --version
run_check "az --version"                az --version
run_check "gh --version"                gh --version
run_check "git --version"               git --version
run_check "clang-format --version"      clang-format --version
run_check "cmake --version"             cmake --version
run_check "rg --version"                rg --version
run_check "shellcheck --version"        shellcheck --version
run_check "markdownlint-cli2 --version" markdownlint-cli2 --version
run_check "cspell --version"            cspell --version
run_check "lychee --version"            lychee --version

echo ""
echo "=== Heavy toolchain must be absent ==="
absent_check "ifx absent"  ifx
absent_check "icx absent"  icx
absent_check "sbcl absent" sbcl
absent_check "go absent"   go

echo ""
echo "=== Hello-world run ==="
run_check "python3 run" python3 -c 'print("Hello from Python")'
run_check "node run"    node -e 'console.log("Hello from Node")'

TMPDIR=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf '$TMPDIR'" EXIT

# clang-format reformats a trivial C source (no compiler needed)
cat > "$TMPDIR/sample.c" << 'EOF'
int main(void){return 0;}
EOF
run_check "clang-format run" clang-format "$TMPDIR/sample.c"

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
