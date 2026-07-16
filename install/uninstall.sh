#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/backup.sh"

uninstall_configs() {
  local mappings
  mappings="$(get_config_mappings "$SCRIPT_DIR")"

  local -a targets=()
  while IFS= read -r mapping; do
    local target="${mapping#*|}"
    targets+=("$target")
  done <<< "$mappings"

  create_backup "${targets[@]}"

  while IFS= read -r mapping; do
    local target="${mapping#*|}"

    if [ -L "$target" ]; then
      rm "$target"
      printf 'removed symlink: %s\n' "$target"
    elif [ -d "$target" ]; then
      rm -rf "$target"
      printf 'removed directory: %s\n' "$target"
    elif [ -e "$target" ]; then
      rm -f "$target"
      printf 'removed file: %s\n' "$target"
    fi
  done <<< "$mappings"

  printf 'uninstall complete\n'
  printf 'a backup was created before removal. use --restore to recover.\n'
}

uninstall_configs
