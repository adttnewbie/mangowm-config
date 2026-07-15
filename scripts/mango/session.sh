#!/usr/bin/env bash
set -eu

action=${1:-}

case "$action" in
  start)
    exec mango
    ;;
  stop)
    exec mmsg dispatch exit
    ;;
  reload)
    exec mmsg dispatch reload_config
    ;;
  *)
    printf 'usage: session.sh {start|stop|reload}\n' >&2
    exit 64
    ;;
esac
