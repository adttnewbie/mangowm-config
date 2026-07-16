#!/usr/bin/env bash
set -eu

if [ "$(id -u)" -eq 0 ]; then
  printf 'ERROR: do not run the installer as root\n' >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/backup.sh"

usage() {
  printf 'Usage: %s [OPTIONS]\n\n' "$0"
  printf 'Options:\n'
  printf '  --copy           Install by copying files (default)\n'
  printf '  --symlink        Install by creating symlinks\n'
  printf '  --force          Overwrite automatically after backup\n'
  printf '  --skip-existing  Leave existing user configurations untouched\n'
  printf '  --dry-run        Simulate installation without modifying files\n'
  printf '  --restore        Restore from backup\n'
  printf '  --uninstall      Remove installed configurations\n'
  printf '  --skip-pkg       Skip package installation\n'
  printf '  --plymouth       Install Plymouth theme\n'
  printf '  --help           Show this help\n'
}

mode="copy"
action="backup_and_overwrite"
dry_run="false"
skip_pkg=false
extra_args=()

while [ $# -gt 0 ]; do
  case "$1" in
    --copy) mode="copy" ;;
    --symlink) mode="symlink" ;;
    --force) action="force" ;;
    --skip-existing) action="skip_existing" ;;
    --dry-run) dry_run="true" ;;
    --restore) mode="restore" ;;
    --uninstall) mode="uninstall" ;;
    --skip-pkg) skip_pkg=true ;;
    --plymouth) extra_args+=("--plymouth") ;;
    --help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1"; usage; exit 1 ;;
  esac
  shift
done

case "$mode" in
  restore)
    printf '=== MangoWM Restore ===\n\n'
    bash "$SCRIPT_DIR/restore.sh" "${extra_args[@]+"${extra_args[@]}"}"
    exit 0
    ;;
  uninstall)
    printf '=== MangoWM Uninstall ===\n\n'
    bash "$SCRIPT_DIR/uninstall.sh"
    exit 0
    ;;
esac

printf '=== MangoWM Arch Linux Installation ===\n'
printf 'Mode: %s\n' "$mode"
if [ "$dry_run" = "true" ]; then
  printf '[dry-run mode]\n'
fi
printf '\n'

if [ "$skip_pkg" = "false" ] && [ "$dry_run" = "false" ]; then
  printf 'Step 1/4: Installing packages...\n'
  bash "$SCRIPT_DIR/packages.sh"
elif [ "$skip_pkg" = "true" ]; then
  printf 'Step 1/4: Skipping packages (--skip-pkg)\n'
else
  printf 'Step 1/4: Skipping packages (dry-run)\n'
fi

printf '\nStep 2/4: Deploying configurations (%s)...\n' "$mode"

detections="$(detect_all "$SCRIPT_DIR" "$mode")"
print_detection_summary "$detections"

if [ "$action" = "backup_and_overwrite" ] && [ "$dry_run" = "false" ]; then
  if has_existing_configs "$detections"; then
    if [ -t 0 ]; then
      action="$(show_interactive_menu)"
      if [ "$action" = "cancel" ]; then
        printf 'Installation cancelled.\n'
        exit 0
      fi
    else
      printf 'Existing configurations found. Use --force, --skip-existing, or run interactively.\n'
      exit 1
    fi
  fi
fi

print_plan "$detections" "$action" "$dry_run"

case "$mode" in
  copy)
    bash "$SCRIPT_DIR/copy.sh" "$action" "$dry_run" "$detections"
    ;;
  symlink)
    bash "$SCRIPT_DIR/symlink.sh" "$action" "$dry_run" "$detections"
    ;;
esac

printf '\nStep 3/4: Installing fonts...\n'
if [ "$dry_run" = "false" ]; then
  bash "$SCRIPT_DIR/fonts.sh"
else
  printf '  [dry-run] skip fonts\n'
fi

printf '\nStep 4/4: Installing themes...\n'
if [ "$dry_run" = "false" ]; then
  bash "$SCRIPT_DIR/themes.sh" "${extra_args[@]+"${extra_args[@]}"}"
else
  printf '  [dry-run] skip themes\n'
fi

if [ "$dry_run" = "false" ]; then
  printf '\n=== Installation complete ===\n'
  printf 'Log out and select "Mango" from your display manager to start the session.\n'
else
  printf '\n=== Dry-run complete ===\n'
  printf 'No files were modified.\n'
fi
