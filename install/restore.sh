#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/backup.sh"

list_backups() {
  if [ ! -d "$BACKUP_BASE" ]; then
    printf 'No backups found.\n'
    return 1
  fi

  local -a backups=()
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    backups+=("$dir")
  done < <(find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d | sort -r)

  if [ ${#backups[@]} -eq 0 ]; then
    printf 'No backups found.\n'
    return 1
  fi

  printf 'Available backups:\n'
  for i in "${!backups[@]}"; do
    printf '  %d) %s\n' "$((i + 1))" "$(basename "${backups[$i]}")"
  done

  printf '%s\n' "${backups[@]}"
}

restore_backup() {
  local backup_dir=$1

  if [ ! -d "$backup_dir" ]; then
    printf 'ERROR: backup directory not found: %s\n' "$backup_dir"
    return 1
  fi

  printf 'Restoring from: %s\n' "$(basename "$backup_dir")"

  find "$backup_dir" -mindepth 1 -maxdepth 1 | while IFS= read -r item; do
    local rel_path="${item#$backup_dir/}"
    local target="$HOME/$rel_path"

    if [ -e "$target" ] || [ -L "$target" ]; then
      case "$target" in
        "$HOME"/*) rm -rf "$target" ;;
        *) printf 'ERROR: refusing to remove path outside HOME: %s\n' "$target" >&2; continue ;;
      esac
    fi

    mkdir -p "$(dirname "$target")"
    cp -a "$item" "$target"
    printf 'restored: %s\n' "$target"
  done

  printf 'restore complete\n'
}

get_latest_backup() {
  if [ ! -d "$BACKUP_BASE" ]; then
    return 1
  fi

  find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n1
}

do_restore() {
  local selection="${1:-}"

  if [ -n "$selection" ] && [ -d "$selection" ]; then
    restore_backup "$selection"
    return
  fi

  local latest
  latest="$(get_latest_backup)" || {
    printf 'No backups found.\n'
    return 1
  }

  if [ -z "$selection" ]; then
    printf 'Restoring latest backup...\n'
    restore_backup "$latest"
    return
  fi

  if [[ "$selection" =~ ^[0-9]+$ ]]; then
    local -a backups=()
    while IFS= read -r dir; do
      [ -z "$dir" ] && continue
      backups+=("$dir")
    done < <(find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d | sort -r)

    local idx=$((selection - 1))
    if [ $idx -ge 0 ] && [ $idx -lt ${#backups[@]} ]; then
      restore_backup "${backups[$idx]}"
    else
      printf 'ERROR: invalid selection: %s\n' "$selection"
      return 1
    fi
  fi
}

if [ "${1:-}" = "--list" ]; then
  list_backups
else
  do_restore "${1:-}"
fi
