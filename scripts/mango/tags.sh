#!/usr/bin/env bash
set -eu

action=${1:-}
tag=${2:-}

case "$action" in
  view)
    exec mmsg dispatch view "$tag"
    ;;
  move)
    exec mmsg dispatch tag "$tag"
    ;;
  list)
    exec mmsg get tags
    ;;
  *)
    printf 'usage: tags.sh {view|move|list} [tag]\n' >&2
    exit 64
    ;;
esac
