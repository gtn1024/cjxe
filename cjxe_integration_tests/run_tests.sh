#!/bin/bash
set -euo pipefail

BINARY="$1"
PASS=0
FAIL=0

run_test() {
    local name="$1"
    shift
    local expected_exit="$1"
    shift

    local output
    output=$("$BINARY" "$@" 2>&1) && actual_exit=0 || actual_exit=$?

    if [ "$actual_exit" -ne "$expected_exit" ]; then
        echo "[FAIL] $name (expected exit=$expected_exit, got exit=$actual_exit)"
        echo "  output: $output"
        FAIL=$((FAIL + 1))
        return
    fi

    echo "[PASS] $name"
    PASS=$((PASS + 1))
}

run_test_with_check() {
    local name="$1"
    shift
    local expected_exit="$1"
    shift
    local expected_pattern="$1"
    shift

    local output
    output=$("$BINARY" "$@" 2>&1) && actual_exit=0 || actual_exit=$?

    if [ "$actual_exit" -ne "$expected_exit" ]; then
        echo "[FAIL] $name (expected exit=$expected_exit, got exit=$actual_exit)"
        echo "  output: $output"
        FAIL=$((FAIL + 1))
        return
    fi

    if ! echo "$output" | grep -q "$expected_pattern"; then
        echo "[FAIL] $name (pattern '$expected_pattern' not found in output)"
        echo "  output: $output"
        FAIL=$((FAIL + 1))
        return
    fi

    echo "[PASS] $name"
    PASS=$((PASS + 1))
}

# Test: --help flag
run_test_with_check "help_long" 0 "FLAGS:" --help
run_test_with_check "help_short" 0 "FLAGS:" -h

# Test: --version flag
run_test_with_check "version_long" 0 "1.0.0" --version
run_test_with_check "version_short" 0 "1.0.0" -v

# Test: option with value
run_test_with_check "option_short_value" 0 "config=myconfig.toml" -r req -c myconfig.toml
run_test_with_check "option_long_equals" 0 "config=app.conf" -r req --config=app.conf
run_test_with_check "option_long_space" 0 "config=app.conf" -r req --config app.conf

# Test: multiple flags combined
run_test_with_check "multiple_flags" 0 "debug=3" -r req -ddd
run_test_with_check "multiple_flags_separate" 0 "debug=2" -r req -d -d

# Test: positional argument
run_test_with_check "positional" 0 "input=data.txt" -r req data.txt

# Test: subcommand
run_test_with_check "subcommand_add" 0 "subcommand=add" -r req add
run_test_with_check "subcommand_add_verbose" 0 "add_verbose=true" -r req add -v
run_test_with_check "subcommand_add_long" 0 "add_verbose=true" -r req add --verbose

# Test: missing required argument
run_test "missing_required" 1 -c conf

# Test: invalid possible value
run_test "invalid_possible_value" 1 -r req -f csv

# Test: valid possible value
run_test_with_check "valid_possible_value" 0 "format=json" -r req -f json

# Test: default value for option (not provided)
run_test_with_check "option_default_not_provided" 0 "port=8080" -r req

# Test: default value for option (user overrides)
run_test_with_check "option_default_user_override" 0 "port=3000" -r req -P 3000

# Test: default value for positional (not provided)
run_test_with_check "positional_default_not_provided" 0 "mode=dev" -r req

# Test: default value for positional (user overrides)
run_test_with_check "positional_default_user_override" 0 "mode=prod" -r req data.txt prod

# Test: default value shown in help
run_test_with_check "help_shows_default" 0 "default: 8080" --help

# Test: double dash separator
run_test_with_check "double_dash" 0 "input=output.txt" -r req -- output.txt

# Test: unknown argument
run_test "unknown_arg" 1 -r req --unknown

echo ""
echo "Results: $PASS passed, $FAIL failed, $((PASS + FAIL)) total"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
