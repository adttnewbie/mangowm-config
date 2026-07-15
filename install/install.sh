#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

printf '=== MangoWM Arch Linux Installation ===\n\n'

printf 'Step 1/4: Installing packages...\n'
bash "$SCRIPT_DIR/packages.sh" "$@"

printf '\nStep 2/4: Creating symlinks...\n'
bash "$SCRIPT_DIR/link.sh"

printf '\nStep 3/4: Installing fonts...\n'
bash "$SCRIPT_DIR/fonts.sh"

printf '\nStep 4/4: Installing themes...\n'
bash "$SCRIPT_DIR/themes.sh" "$@"

printf '\n=== Installation complete ===\n'
printf 'Log out and select "Mango" from your display manager to start the session.\n'
