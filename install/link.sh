#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

link_target() {
  local source=$1
  local target=$2
  local dry_run=${3:-false}

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    return 0
  fi

  if [ "$dry_run" = "true" ]; then
    printf '[dry-run] %s -> %s\n' "$target" "$source"
    return 0
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="${target}.bak-$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
}

dry_run=false
if [ "${1:-}" = "--dry-run" ]; then
  dry_run=true
fi

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

link_target "$REPO_ROOT/config/sessions/mango" "$XDG_CONFIG_HOME/mango" "$dry_run"
link_target "$REPO_ROOT/config/programs/kitty" "$XDG_CONFIG_HOME/kitty" "$dry_run"
link_target "$REPO_ROOT/config/programs/rofi" "$XDG_CONFIG_HOME/rofi" "$dry_run"
link_target "$REPO_ROOT/config/programs/cava" "$XDG_CONFIG_HOME/cava" "$dry_run"
link_target "$REPO_ROOT/config/programs/neovim" "$XDG_CONFIG_HOME/nvim" "$dry_run"
link_target "$REPO_ROOT/config/programs/zsh" "$XDG_CONFIG_HOME/zsh" "$dry_run"
link_target "$REPO_ROOT/config/programs/matugen" "$XDG_CONFIG_HOME/matugen" "$dry_run"
link_target "$REPO_ROOT/quickshell" "$XDG_CONFIG_HOME/quickshell" "$dry_run"
link_target "$REPO_ROOT/scripts" "$XDG_DATA_HOME/mango/scripts" "$dry_run"
