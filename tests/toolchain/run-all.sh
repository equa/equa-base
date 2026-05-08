#!/bin/bash
# Toolchain smoke test for equa-base image.
# Each test exits non-zero on failure (set -e enforces this).
# Run inside the built image:
#   docker run --rm equa-base:test bash /tmp/run-all.sh

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

# Set oneAPI paths directly (APT install; avoids setvars.sh calling exit)
export PATH="/opt/intel/oneapi/compiler/latest/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/lib:${LD_LIBRARY_PATH:-}"

echo "=== Tool version checks ==="
run_check "ifx --version"             ifx --version
run_check "icx --version"             icx --version
run_check "sbcl --version"            sbcl --version
run_check "go version"                go version
run_check "python3 --version"         python3 --version
run_check "node --version"            node --version
run_check "uv --version"              uv --version
run_check "az --version"              az --version
run_check "gh --version"              gh --version
run_check "markdownlint-cli2 --version" markdownlint-cli2 --version
run_check "cspell --version"          cspell --version
run_check "lychee --version"          lychee --version

echo ""
echo "=== Hello-world compile + run ==="

TMPDIR=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf '$TMPDIR'" EXIT

# C — icx
cat > "$TMPDIR/hello.c" << 'EOF'
#include <stdio.h>
int main(void) { printf("Hello from C\n"); return 0; }
EOF
icx -o "$TMPDIR/hello_c" "$TMPDIR/hello.c"
run_check "icx compile+run" "$TMPDIR/hello_c"

# C++ — icx
cat > "$TMPDIR/hello.cpp" << 'EOF'
#include <iostream>
int main() { std::cout << "Hello from C++\n"; return 0; }
EOF
icpx -o "$TMPDIR/hello_cpp" "$TMPDIR/hello.cpp"
run_check "icpx compile+run" "$TMPDIR/hello_cpp"

# Fortran — ifx
cat > "$TMPDIR/hello.f90" << 'EOF'
program hello
  print *, "Hello from Fortran"
end program hello
EOF
ifx -o "$TMPDIR/hello_f90" "$TMPDIR/hello.f90"
run_check "ifx compile+run" "$TMPDIR/hello_f90"

# Common Lisp — sbcl
run_check "sbcl run" sbcl --noinform --eval '(progn (format t "Hello from SBCL~%") (quit))'

# Go
cat > "$TMPDIR/hello.go" << 'EOF'
package main
import "fmt"
func main() { fmt.Println("Hello from Go") }
EOF
run_check "go run" go run "$TMPDIR/hello.go"

# Python
run_check "python3 run" python3 -c 'print("Hello from Python")'

# Node
run_check "node run" node -e 'console.log("Hello from Node")'

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
