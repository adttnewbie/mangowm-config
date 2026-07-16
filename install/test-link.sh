#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

run_test() {
  local mode=$1
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  export XDG_CONFIG_HOME="$tmp/config"
  export XDG_DATA_HOME="$tmp/data"
  export HOME="$tmp/home"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$HOME"

  mkdir -p "$XDG_CONFIG_HOME/mango"
  printf 'original content\n' > "$XDG_CONFIG_HOME/mango/test-file"

  bash "$SCRIPT_DIR/$mode.sh" "force" "false"

  if [ "$mode" = "symlink" ]; then
    if [ ! -L "$XDG_CONFIG_HOME/mango" ]; then
      printf 'FAIL [%s]: mango is not a symlink\n' "$mode"
      return 1
    fi
  else
    if [ -L "$XDG_CONFIG_HOME/mango" ]; then
      printf 'FAIL [%s]: mango should not be a symlink\n' "$mode"
      return 1
    fi
    if [ ! -d "$XDG_CONFIG_HOME/mango" ]; then
      printf 'FAIL [%s]: mango directory not found\n' "$mode"
      return 1
    fi
  fi

  local backup_base="${XDG_CONFIG_HOME}-backup"
  if [ ! -d "$backup_base" ]; then
    printf 'FAIL [%s]: backup directory not created\n' "$mode"
    return 1
  fi

  local backup_count
  backup_count=$(find "$backup_base" -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [ "$backup_count" -ne 1 ]; then
    printf 'FAIL [%s]: expected 1 backup, found %d\n' "$mode" "$backup_count"
    return 1
  fi

  bash "$SCRIPT_DIR/$mode.sh" "force" "false"

  local new_backup_count
  new_backup_count=$(find "$backup_base" -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [ "$new_backup_count" -ne 1 ]; then
    printf 'FAIL [%s]: expected 1 backup after re-run, found %d\n' "$mode" "$new_backup_count"
    return 1
  fi

  if [ "$mode" = "symlink" ]; then
    local broken
    broken=$(find "$tmp" -xtype l 2>/dev/null || true)
    if [ -n "$broken" ]; then
      printf 'FAIL [%s]: broken symlinks found:\n%s\n' "$mode" "$broken"
      return 1
    fi
  fi

  printf 'PASS [%s]: all tests passed\n' "$mode"
}

run_skip_test() {
  local mode=$1
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  export XDG_CONFIG_HOME="$tmp/config"
  export XDG_DATA_HOME="$tmp/data"
  export HOME="$tmp/home"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$HOME"

  mkdir -p "$XDG_CONFIG_HOME/kitty"
  printf 'user config\n' > "$XDG_CONFIG_HOME/kitty/kitty.conf"

  bash "$SCRIPT_DIR/$mode.sh" "skip_existing" "false"

  if [ "$mode" = "copy" ]; then
    if [ ! -f "$XDG_CONFIG_HOME/kitty/kitty.conf" ]; then
      printf 'FAIL [%s-skip]: kitty.conf was removed\n' "$mode"
      return 1
    fi
    local content
    content=$(cat "$XDG_CONFIG_HOME/kitty/kitty.conf")
    if [ "$content" != "user config" ]; then
      printf 'FAIL [%s-skip]: kitty.conf was overwritten\n' "$mode"
      return 1
    fi
  else
    if [ -L "$XDG_CONFIG_HOME/kitty" ]; then
      printf 'FAIL [%s-skip]: kitty should not be a symlink when skipping\n' "$mode"
      return 1
    fi
    if [ ! -f "$XDG_CONFIG_HOME/kitty/kitty.conf" ]; then
      printf 'FAIL [%s-skip]: kitty.conf was removed\n' "$mode"
      return 1
    fi
  fi

  printf 'PASS [%s-skip]: skip-existing test passed\n' "$mode"
}

run_dry_run_test() {
  local mode=$1
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  export XDG_CONFIG_HOME="$tmp/config"
  export XDG_DATA_HOME="$tmp/data"
  export HOME="$tmp/home"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$HOME"

  bash "$SCRIPT_DIR/$mode.sh" "force" "true"

  if [ -d "$XDG_CONFIG_HOME/mango" ]; then
    printf 'FAIL [%s-dry-run]: mango should not exist after dry-run\n' "$mode"
    return 1
  fi

  local backup_base="${XDG_CONFIG_HOME}-backup"
  if [ -d "$backup_base" ]; then
    printf 'FAIL [%s-dry-run]: backup should not exist after dry-run\n' "$mode"
    return 1
  fi

  printf 'PASS [%s-dry-run]: dry-run test passed\n' "$mode"
}

run_test "copy"
run_test "symlink"
run_skip_test "copy"
run_skip_test "symlink"
run_dry_run_test "copy"
run_dry_run_test "symlink"
