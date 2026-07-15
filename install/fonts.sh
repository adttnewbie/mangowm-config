#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
FONT_DIR="$XDG_DATA_HOME/fonts"

mkdir -p "$FONT_DIR"

if [ -d "$REPO_ROOT/config/fonts" ]; then
  printf 'Installing fonts...\n'
  cp -r "$REPO_ROOT/config/fonts/"* "$FONT_DIR/" 2>/dev/null || true
fi

if command -v fc-cache >/dev/null 2>&1; then
  printf 'Refreshing font cache...\n'
  fc-cache -f
fi

printf 'Fonts installed to %s\n' "$FONT_DIR"
