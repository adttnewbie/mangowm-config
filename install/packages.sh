#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pacman_only=false
aur_only=false

for arg in "$@"; do
  case "$arg" in
    --pacman-only) pacman_only=true ;;
    --aur-only) aur_only=true ;;
  esac
done

detect_aur_helper() {
  if command -v yay >/dev/null 2>&1; then
    echo "yay"
  elif command -v paru >/dev/null 2>&1; then
    echo "paru"
  else
    echo ""
  fi
}

install_pacman_packages() {
  local pkg_file="$REPO_ROOT/packages-pacman.txt"
  if [ ! -f "$pkg_file" ]; then
    printf 'WARN: %s not found\n' "$pkg_file"
    return 0
  fi

  local packages=()
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [ -z "$line" ] && continue
    packages+=("$line")
  done < "$pkg_file"

  if [ ${#packages[@]} -eq 0 ]; then
    return 0
  fi

  printf 'Installing %d official packages...\n' "${#packages[@]}"
  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

install_aur_packages() {
  local pkg_file="$REPO_ROOT/packages-aur.txt"
  if [ ! -f "$pkg_file" ]; then
    printf 'WARN: %s not found\n' "$pkg_file"
    return 0
  fi

  local helper
  helper=$(detect_aur_helper)
  if [ -z "$helper" ]; then
    printf 'ERROR: No AUR helper found. Install yay or paru first.\n'
    exit 1
  fi

  local packages=()
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [ -z "$line" ] && continue
    packages+=("$line")
  done < "$pkg_file"

  if [ ${#packages[@]} -eq 0 ]; then
    return 0
  fi

  printf 'Installing %d AUR packages with %s...\n' "${#packages[@]}" "$helper"
  "$helper" -S --needed --noconfirm "${packages[@]}"
}

if [ "$pacman_only" = "true" ]; then
  install_pacman_packages
elif [ "$aur_only" = "true" ]; then
  install_aur_packages
else
  install_pacman_packages
  install_aur_packages
fi
