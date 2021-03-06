#! /bin/bash
#
# Assertions for Bats tests
#
# Felt the need for this after several Travis breakages without helpful output,
# then stole some inspiration from rbenv/test/test_helper.bash.

__return_from_bats_assertion() {
  local result="${1:-0}"

  if [[ "${BATS_CURRENT_STACK_TRACE[0]}" =~ $BASH_SOURCE ]]; then
    unset "BATS_CURRENT_STACK_TRACE[0]"
  fi

  if [[ "${BATS_PREVIOUS_STACK_TRACE[0]}" =~ $BASH_SOURCE ]]; then
    unset "BATS_PREVIOUS_STACK_TRACE[0]"
  fi

  set -o functrace
  return "$result"
}

fail() {
  set +o functrace
  printf 'STATUS: %s\nOUTPUT:\n%s\n' "$status" "$output" >&2
  __return_from_bats_assertion 1
}

assert_equal() {
  set +o functrace
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "$expected" != "$actual" ]]; then
    printf '%s not equal to expected value:\n  %s\n  %s\n' \
      "$label" "expected: '$expected'" "actual:   '$actual'" >&2
    __return_from_bats_assertion 1
  else
    __return_from_bats_assertion
  fi
}

assert_matches() {
  set +o functrace
  local pattern="$1"
  local value="$2"
  local label="$3"

  if [[ ! "$value" =~ $pattern ]]; then
    printf '%s does not match expected pattern:\n  %s\n  %s\n' \
      "$label" "pattern: '$pattern'" "value:   '$value'" >&2
    __return_from_bats_assertion 1
  else
    __return_from_bats_assertion
  fi
}

__assert_output() {
  local assertion="$1"
  shift

  if [[ "$#" -eq '0' ]]; then
    __return_from_bats_assertion
  elif [[ "$#" -ne 1 ]]; then
    echo "ERROR: ${FUNCNAME[1]} takes only one argument" >&2
    __return_from_bats_assertion 1
  else
    "$assertion" "$1" "$output" 'output'
  fi
}

assert_output() {
  set +o functrace
  __assert_output 'assert_equal' "$@"
}

assert_output_matches() {
  set +o functrace
  __assert_output 'assert_matches' "$@"
}

assert_status() {
  set +o functrace
  assert_equal "$1" "$status" "exit status"
}

assert_success() {
  set +o functrace
  if [[ "$status" -ne '0' ]]; then
    printf 'expected success, but command failed\n' >&2
    fail
  elif [[ "$#" -ne 0 ]]; then
    assert_output "$@"
  fi
}

assert_failure() {
  set +o functrace
  if [[ "$status" -eq '0' ]]; then
    printf 'expected failure, but command succeeded\n' >&2
    fail
  elif [[ "$#" -ne 0 ]]; then
    assert_output "$@"
  fi
}

__assert_line() {
  local assertion="$1"
  local lineno="$2"
  local constraint="$3"

  # Implement negative indices for Bash 3.x.
  if [[ "${lineno:0:1}" == '-' ]]; then
    lineno="$((${#lines[@]} - ${lineno:1}))"
  fi

  if ! "$assertion" "$constraint" "${lines[$lineno]}" "line $lineno"; then
    printf 'OUTPUT:\n%s\n' "$output" >&2
    __return_from_bats_assertion 1
  else
    __return_from_bats_assertion
  fi
}

assert_line_equals() {
  set +o functrace
  __assert_line 'assert_equal' "$@"
}

assert_line_matches() {
  set +o functrace
  __assert_line 'assert_matches' "$@"
}
