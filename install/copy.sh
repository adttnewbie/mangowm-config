#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/backup.sh"

run_copy_install() {
  local action="${1:-backup_and_overwrite}"
  local dry_run="${2:-false}"
  local detections="${3:-}"

  if [ -z "$detections" ]; then
    detections="$(detect_all "$SCRIPT_DIR" "copy")"
    print_detection_summary "$detections"

    if has_existing_configs "$detections" && [ "$action" = "backup_and_overwrite" ] && [ "$dry_run" = "false" ]; then
      if [ -t 0 ]; then
        action="$(show_interactive_menu)"
        if [ "$action" = "cancel" ]; then
          printf 'Installation cancelled.\n'
          return 1
        fi
      fi
    fi

    print_plan "$detections" "$action" "$dry_run"
  fi

  local installed=0
  local skipped=0
  local backed_up=0
  local failed=0
  local -a backup_targets=()

  while IFS='|' read -r name source target state mapping; do
    if should_install "$state" "$action"; then
      if should_backup "$state" "$action"; then
        backup_targets+=("$target")
      fi
    else
      skipped=$((skipped + 1))
    fi
  done <<< "$detections"

  if [ ${#backup_targets[@]} -gt 0 ] && [ "$dry_run" = "false" ]; then
    create_backup "${backup_targets[@]}"
    backed_up=${#backup_targets[@]}
  fi

  while IFS='|' read -r name source target state mapping; do
    if should_install "$state" "$action"; then
      if deploy_copy "$source" "$target" "$dry_run"; then
        installed=$((installed + 1))
      else
        failed=$((failed + 1))
      fi
    fi
  done <<< "$detections"

  if [ "$dry_run" = "false" ] && [ "$installed" -gt 0 ]; then
    local mappings
    mappings="$(get_config_mappings "$SCRIPT_DIR")"
    save_manifest "copy" "$mappings"
  fi

  print_post_summary "$installed" "$skipped" "$backed_up" "$failed" "$dry_run"
}

run_copy_install "${1:-backup_and_overwrite}" "${2:-false}" "${3:-}"
