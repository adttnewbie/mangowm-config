#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

export XDG_CONFIG_HOME="$tmp/config"
export XDG_DATA_HOME="$tmp/data"

mkdir -p "$XDG_CONFIG_HOME/mango"
printf 'original content\n' > "$XDG_CONFIG_HOME/mango/test-file"

bash "$SCRIPT_DIR/link.sh"

if [ ! -L "$XDG_CONFIG_HOME/mango" ]; then
  printf 'FAIL: mango is not a symlink\n'
  exit 1
fi

backups=$(find "$XDG_CONFIG_HOME" -name '*.bak-*' | wc -l)
if [ "$backups" -ne 1 ]; then
  printf 'FAIL: expected 1 backup, found %d\n' "$backups"
  exit 1
fi

bash "$SCRIPT_DIR/link.sh"

new_backups=$(find "$XDG_CONFIG_HOME" -name '*.bak-*' | wc -l)
if [ "$new_backups" -ne 1 ]; then
  printf 'FAIL: expected 1 backup after re-run, found %d\n' "$new_backups"
  exit 1
fi

broken=$(find "$tmp" -xtype l)
if [ -n "$broken" ]; then
  printf 'FAIL: broken symlinks found:\n%s\n' "$broken"
  exit 1
fi

printf 'PASS: all link tests passed\n'
