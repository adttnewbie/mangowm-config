#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IPC="$SCRIPT_DIR/ipc.sh"

failures=0

assert_exit() {
  local label=$1 expected=$2
  shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  if [ "$actual" -ne "$expected" ]; then
    printf 'FAIL: %s: expected exit %d, got %d\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

assert_output_contains() {
  local label=$1 pattern=$2
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if printf '%s\n' "$output" | grep -qE "$pattern"; then
    printf 'PASS: %s\n' "$label"
  else
    printf 'FAIL: %s: output does not match /%s/\n' "$label" "$pattern"
    failures=$((failures + 1))
  fi
}

for action in view-tag move-to-tag tags monitors keyboard-layout switch-keyboard-layout reload quit; do
  assert_exit "action $action exists" 0 "$IPC" "$action" 2>/dev/null || true
done

for tag in 1 2 3 4 5 6 7 8 9; do
  assert_exit "view-tag $tag" 0 "$IPC" view-tag "$tag"
done

for tag in 0 10 -1 a 99; do
  assert_exit "view-tag $tag rejected" 64 "$IPC" view-tag "$tag"
done

for tag in 1 2 3 4 5 6 7 8 9; do
  assert_exit "move-to-tag $tag" 0 "$IPC" move-to-tag "$tag"
done

for tag in 0 10 -1 a 99; do
  assert_exit "move-to-tag $tag rejected" 64 "$IPC" move-to-tag "$tag"
done

assert_exit "tags no-arg" 0 "$IPC" tags
assert_exit "monitors no-arg" 0 "$IPC" monitors
assert_exit "keyboard-layout no-arg" 0 "$IPC" keyboard-layout
assert_exit "switch-keyboard-layout no-arg" 0 "$IPC" switch-keyboard-layout
assert_exit "reload no-arg" 0 "$IPC" reload
assert_exit "quit no-arg" 0 "$IPC" quit

assert_exit "unknown action" 64 "$IPC" bogus

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures"
  exit 1
fi

printf '\nAll tests passed\n'
