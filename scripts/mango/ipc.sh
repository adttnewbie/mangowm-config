#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

validate_tag() {
  case "$1" in
    [1-9]) return 0 ;;
    *) printf 'invalid tag: %s (must be 1-9)\n' "$1" >&2; return 64 ;;
  esac
}

action=${1:-}
shift || true

case "$action" in
  view-tag)
    validate_tag "$1"
    exec "$SCRIPT_DIR/tags.sh" view "$1"
    ;;
  move-to-tag)
    validate_tag "$1"
    exec "$SCRIPT_DIR/tags.sh" move "$1"
    ;;
  tags)
    exec "$SCRIPT_DIR/tags.sh" list
    ;;
  monitors)
    exec "$SCRIPT_DIR/monitors.sh"
    ;;
  keyboard-layout)
    exec "$SCRIPT_DIR/keyboard.sh" get
    ;;
  switch-keyboard-layout)
    exec "$SCRIPT_DIR/keyboard.sh" switch
    ;;
  reload)
    exec mmsg dispatch reload_config
    ;;
  quit)
    exec mmsg dispatch exit
    ;;
  *)
    printf 'unknown action: %s\n' "$action" >&2
    printf 'usage: ipc.sh {view-tag|move-to-tag|tags|monitors|keyboard-layout|switch-keyboard-layout|reload|quit} [arg]\n' >&2
    exit 64
    ;;
esac
