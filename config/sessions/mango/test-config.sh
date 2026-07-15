#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR"

failures=0

assert_contains() {
  local file=$1 pattern=$2 label=$3
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    printf 'PASS: %s\n' "$label"
  else
    printf 'FAIL: %s: pattern /%s/ not found in %s\n' "$label" "$pattern" "$file"
    failures=$((failures + 1))
  fi
}

assert_not_contains() {
  local dir=$1 pattern=$2 label=$3
  if grep -rqE --exclude='test-config.sh' "$pattern" "$dir" 2>/dev/null; then
    printf 'FAIL: %s: pattern /%s/ found in %s\n' "$label" "$pattern" "$dir"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

assert_contains "$CONFIG_DIR/conf.d/bindings.conf" 'bind=SUPER,1,view,1' 'tag 1 binding'
assert_contains "$CONFIG_DIR/conf.d/bindings.conf" 'bind=SUPER,9,view,9' 'tag 9 binding'
assert_contains "$CONFIG_DIR/conf.d/bindings.conf" 'bind=SUPER\+SHIFT,1,tag,1' 'move to tag 1'
assert_contains "$CONFIG_DIR/conf.d/autostart.conf" 'exec-once=quickshell' 'quickshell autostart'
assert_contains "$CONFIG_DIR/conf.d/autostart.conf" 'exec-once=swww-daemon' 'swww autostart'
assert_contains "$CONFIG_DIR/conf.d/autostart.conf" 'exec-once=swayidle' 'swayidle autostart'

assert_not_contains "$CONFIG_DIR" 'hyprctl' 'no hyprctl'
assert_not_contains "$CONFIG_DIR" 'HYPRLAND' 'no HYPRLAND'
assert_not_contains "$CONFIG_DIR" 'NIXOS_OZONE_WL' 'no NIXOS_OZONE_WL'
assert_not_contains "$CONFIG_DIR" '/run/current-system' 'no /run/current-system'
assert_not_contains "$CONFIG_DIR" '/nix/store' 'no /nix/store'

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures"
  exit 1
fi

printf '\nAll tests passed\n'
