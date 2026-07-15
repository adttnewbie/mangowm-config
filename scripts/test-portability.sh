#!/usr/bin/env bash
set -eu

failures=0

check_no_pattern() {
  local dir=$1 pattern=$2 label=$3
  if find "$dir" -type f \( -name '*.sh' -o -name '*.qml' -o -name '*.py' -o -name '*.conf' -o -name '*.toml' -o -name '*.plymouth' \) ! -name 'test-portability.sh' -exec grep -qE "$pattern" {} + 2>/dev/null; then
    printf 'FAIL: %s: pattern /%s/ found\n' "$label" "$pattern"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

check_no_pattern "quickshell" '~/.config/hypr|\.config/hypr' 'no hypr config paths in quickshell'
check_no_pattern "scripts" '~/.config/hypr|\.config/hypr' 'no hypr config paths in scripts'
check_no_pattern "config/programs" '~/.config/hypr|\.config/hypr' 'no hypr config paths in config/programs'

check_no_pattern "quickshell" 'hyprctl' 'no hyprctl in quickshell'
check_no_pattern "scripts" 'hyprctl' 'no hyprctl in scripts'
check_no_pattern "config/programs" 'hyprctl' 'no hyprctl in config/programs'

check_no_pattern "quickshell" 'HYPRLAND_INSTANCE_SIGNATURE' 'no HYPRLAND_INSTANCE_SIGNATURE'
check_no_pattern "scripts" 'HYPRLAND_INSTANCE_SIGNATURE' 'no HYPRLAND_INSTANCE_SIGNATURE in scripts'

check_no_pattern "quickshell" '/run/current-system' 'no /run/current-system in quickshell'
check_no_pattern "scripts" '/run/current-system' 'no /run/current-system in scripts'
check_no_pattern "config/programs" '/run/current-system' 'no /run/current-system in config/programs'

check_no_pattern "quickshell" '/etc/nixos' 'no /etc/nixos in quickshell'
check_no_pattern "scripts" '/etc/nixos' 'no /etc/nixos in scripts'

check_no_pattern "quickshell" '$HOME' 'no hardcoded home in quickshell'
check_no_pattern "scripts" '$HOME' 'no hardcoded home in scripts'
check_no_pattern "config/programs" '$HOME' 'no hardcoded home in config/programs'

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures"
  exit 1
fi

printf '\nAll portability tests passed\n'
