#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

install_plymouth=false

for arg in "$@"; do
  case "$arg" in
    --plymouth) install_plymouth=true ;;
  esac
done

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

if [ -d "$REPO_ROOT/config/programs/plymouth" ] && [ "$install_plymouth" = "true" ]; then
  printf 'Installing Plymouth theme (requires sudo)...\n'
  if [ -d "$REPO_ROOT/config/programs/plymouth/simple" ]; then
    sudo cp -r "$REPO_ROOT/config/programs/plymouth/simple" /usr/share/plymouth/themes/mango-simple
    sudo plymouth-set-default-theme -R mango-simple
    printf 'Plymouth theme installed\n'
  fi
fi

printf 'Theme installation complete\n'
