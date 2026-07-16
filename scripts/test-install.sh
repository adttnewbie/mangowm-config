#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEMP_HOME=$(mktemp -d)
trap 'rm -rf "$TEMP_HOME"' EXIT

export HOME="$TEMP_HOME"
export XDG_CONFIG_HOME="$TEMP_HOME/.config"
export XDG_DATA_HOME="$TEMP_HOME/.local/share"
export XDG_CACHE_HOME="$TEMP_HOME/.cache"

mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"

printf 'Creating symlinks...\n'
bash "$REPO_ROOT/install/symlink.sh" >/dev/null 2>&1

printf 'Checking for broken symlinks...\n'
broken=$(find "$XDG_CONFIG_HOME" -xtype l 2>/dev/null || true)
if [ -n "$broken" ]; then
  printf 'FAIL: broken symlinks found:\n%s\n' "$broken"
  exit 1
fi
printf 'PASS: no broken symlinks\n'

printf 'Checking Mango config syntax...\n'
if command -v mango >/dev/null 2>&1; then
  mango -c "$XDG_CONFIG_HOME/mango/config.conf" -p >/dev/null 2>&1
  printf 'PASS: Mango config parses successfully\n'
else
  printf 'SKIP: mango not installed\n'
fi

printf 'Running portability tests...\n'
bash "$REPO_ROOT/scripts/test-portability.sh" >/dev/null 2>&1
printf 'PASS: portability tests\n'

printf 'Running no-Nix tests...\n'
bash "$REPO_ROOT/scripts/test-no-nix.sh" >/dev/null 2>&1
printf 'PASS: no-Nix tests\n'

printf 'Running shell syntax checks...\n'
find "$REPO_ROOT" -name '*.sh' -type f -exec bash -n {} \;
printf 'PASS: all shell scripts have valid syntax\n'

printf '\nAll installation tests passed\n'
