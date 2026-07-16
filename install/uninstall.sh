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

  printf 'This will remove the following configurations:\n'
  for target in "${targets[@]}"; do
    printf '  %s\n' "$target"
  done
  printf '\nA backup will be created before removal.\n'
  printf 'Continue? [y/N] '
  read -r confirm
  case "$confirm" in
    [yY]|[yY][eE][sS]) ;;
    *) printf 'Aborted.\n'; exit 0 ;;
  esac

  create_backup "${targets[@]}"

  while IFS= read -r mapping; do
    local target="${mapping#*|}"

    if [ -L "$target" ]; then
      rm "$target"
      printf 'removed symlink: %s\n' "$target"
    elif [ -d "$target" ]; then
      case "$target" in
        "$HOME"/*) rm -rf "$target"; printf 'removed directory: %s\n' "$target" ;;
        *) printf 'ERROR: refusing to remove directory outside HOME: %s\n' "$target" >&2 ;;
      esac
    elif [ -e "$target" ]; then
      rm -f "$target"
      printf 'removed file: %s\n' "$target"
    fi
  done <<< "$mappings"

  printf 'uninstall complete\n'
  printf 'a backup was created before removal. use --restore to recover.\n'
}

uninstall_configs
