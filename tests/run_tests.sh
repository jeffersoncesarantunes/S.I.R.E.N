#!/usr/bin/env bash
set -euo pipefail

# S.I.R.E.N functional test suite — validates security invariants and
# shell syntax across the codebase.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT_DIR=$(dirname "$SCRIPT_DIR")

failures=0

check() {
    local desc=$1
    shift
    if "$@"; then
        echo "  [PASS] $desc"
    else
        echo "  [FAIL] $desc"
        failures=$((failures + 1))
    fi
}

echo "S.I.R.E.N Test Suite"
echo "────────────────────"
echo

echo "--- Shell syntax ---"
while IFS= read -r f; do
    check "syntax: $f" bash -n "$f"
done < <(find "$ROOT_DIR/src" "$ROOT_DIR/lib" -name '*.sh' 2>/dev/null)

echo
echo "--- Security invariants ---"

check "siren.sh sets umask 077" grep -q "umask 077" "$ROOT_DIR/src/siren.sh"
if grep -q 'umask 022' "$ROOT_DIR/src/siren.sh"; then
    echo "  [FAIL] umask 022 still present"
    failures=$((failures + 1))
else
    echo "  [PASS] no umask 022"
fi

if grep -rn 'eval' "$ROOT_DIR/lib/" "$ROOT_DIR/src/" 2>/dev/null | grep -v '^\s*#'; then
    echo "  [FAIL] eval detected in shell scripts"
    failures=$((failures + 1))
else
    echo "  [PASS] no eval in shell scripts"
fi

check "set -euo pipefail present" grep -q 'set -euo pipefail' "$ROOT_DIR/src/siren.sh"

echo
echo "--- --output guard ---"
check "--output requires a value" grep -q 'requires a directory argument' "$ROOT_DIR/src/siren.sh"

echo
if [[ $failures -eq 0 ]]; then
    echo "All tests passed."
    exit 0
fi
echo "$failures test(s) FAILED."
exit 1
