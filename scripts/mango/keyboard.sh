#!/usr/bin/env bash
set -eu

action=${1:-get}

case "$action" in
  get)
    exec mmsg get keyboard
    ;;
  switch)
    exec mmsg dispatch switch_keyboard_layout
    ;;
  *)
    printf 'usage: keyboard.sh {get|switch}\n' >&2
    exit 64
    ;;
esac
