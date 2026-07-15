#!/usr/bin/env bash
set -eu

failures=0

nix_files=$(git ls-files '*.nix' 2>/dev/null)
if [ -n "$nix_files" ]; then
  printf 'FAIL: Nix files still tracked:\n%s\n' "$nix_files"
  failures=$((failures + 1))
else
  printf 'PASS: no Nix files tracked\n'
fi

check_no_nix_pattern() {
  local pattern=$1 label=$2
  if find . -type f \( -name '*.sh' -o -name '*.qml' -o -name '*.py' -o -name '*.conf' -o -name '*.toml' -o -name '*.md' -o -name '*.txt' \) ! -path './MIGRATION.md' ! -path './docs/migration.md' ! -path './docs/architecture.md' ! -path './docs/superpowers/*' ! -name 'test-no-nix.sh' ! -name 'test-portability.sh' ! -path './config/sessions/mango/test-config.sh' -exec grep -qiE "$pattern" {} + 2>/dev/null; then
    printf 'FAIL: %s: pattern /%s/ found\n' "$label" "$pattern"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

check_no_nix_pattern 'home-manager|nixos|nixpkgs' 'no NixOS references'
check_no_nix_pattern '/nix/store|/run/current-system|/etc/nixos' 'no Nix paths'
check_no_nix_pattern 'nix develop|nixos-rebuild' 'no Nix commands'

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures"
  exit 1
fi

printf '\nAll no-Nix tests passed\n'
