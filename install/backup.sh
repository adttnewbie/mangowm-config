#!/usr/bin/env bash
set -eu

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUP_BASE="${XDG_CONFIG_HOME}-backup"
MANIFEST_FILE="$XDG_DATA_HOME/mango/.install-manifest"

safe_remove() {
  local path=$1
  case "$path" in
    "$HOME"/*) ;;
    *) printf 'ERROR: refusing to remove path outside HOME: %s\n' "$path" >&2; return 1 ;;
  esac
  rm -rf "$path"
}

generate_checksum() {
  local path=$1
  if [ -d "$path" ]; then
    (cd "$path" && find . -type f -print0 2>/dev/null | sort -z | xargs -0 cat 2>/dev/null | md5sum | cut -d' ' -f1)
  elif [ -f "$path" ]; then
    md5sum "$path" | cut -d' ' -f1
  else
    printf 'none'
  fi
}

save_manifest() {
  local mode=$1
  local mappings=$2
  mkdir -p "$(dirname "$MANIFEST_FILE")"
  printf '%s\n' "mode=$mode" > "$MANIFEST_FILE"
  while IFS= read -r mapping; do
    local source="${mapping%%|*}"
    local target="${mapping#*|}"
    local checksum
    checksum="$(generate_checksum "$source")"
    printf '%s|%s|%s\n' "$target" "$source" "$checksum" >> "$MANIFEST_FILE"
  done <<< "$mappings"
}

read_manifest_mode() {
  if [ ! -f "$MANIFEST_FILE" ]; then
    return 1
  fi
  local line
  line="$(head -n1 "$MANIFEST_FILE")"
  if [[ "$line" == mode=* ]]; then
    printf '%s' "${line#mode=}"
    return 0
  fi
  return 1
}

manifest_has_target() {
  local target=$1
  if [ ! -f "$MANIFEST_FILE" ]; then
    return 1
  fi
  while IFS='|' read -r m_target _ _; do
    if [ "$m_target" = "$target" ]; then
      return 0
    fi
  done < <(tail -n +2 "$MANIFEST_FILE")
  return 1
}

manifest_get_checksum() {
  local target=$1
  if [ ! -f "$MANIFEST_FILE" ]; then
    return 1
  fi
  while IFS='|' read -r m_target _ m_checksum; do
    if [ "$m_target" = "$target" ]; then
      printf '%s' "$m_checksum"
      return 0
    fi
  done < <(tail -n +2 "$MANIFEST_FILE")
  return 1
}

get_backup_dir() {
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  printf '%s/%s' "$BACKUP_BASE" "$timestamp"
}

backup_target() {
  local target=$1
  local backup_dir=$2

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  local rel_path="${target#$HOME/}"
  local dest="$backup_dir/$rel_path"

  mkdir -p "$(dirname "$dest")"
  cp -a "$target" "$dest"
  printf '  backed up: %s\n' "$target"
}

create_backup() {
  local -a targets=("$@")
  local -a existing=()

  for target in "${targets[@]}"; do
    if [ -e "$target" ] || [ -L "$target" ]; then
      existing+=("$target")
    fi
  done

  if [ ${#existing[@]} -eq 0 ]; then
    return 0
  fi

  local backup_dir
  backup_dir="$(get_backup_dir)"
  mkdir -p "$backup_dir"

  for target in "${existing[@]}"; do
    backup_target "$target" "$backup_dir"
  done

  printf '  backup created: %s\n' "$backup_dir"
}

get_config_mappings() {
  local script_dir=$1
  local repo_root
  repo_root="$(cd "$script_dir/.." && pwd)"

  printf '%s\n' \
    "$repo_root/config/sessions/mango|$XDG_CONFIG_HOME/mango" \
    "$repo_root/config/programs/kitty|$XDG_CONFIG_HOME/kitty" \
    "$repo_root/config/programs/rofi|$XDG_CONFIG_HOME/rofi" \
    "$repo_root/config/programs/cava|$XDG_CONFIG_HOME/cava" \
    "$repo_root/config/programs/neovim|$XDG_CONFIG_HOME/nvim" \
    "$repo_root/config/programs/zsh|$XDG_CONFIG_HOME/zsh" \
    "$repo_root/config/programs/matugen|$XDG_CONFIG_HOME/matugen" \
    "$repo_root/quickshell|$XDG_CONFIG_HOME/quickshell" \
    "$repo_root/scripts|$XDG_DATA_HOME/mango/scripts"
}

target_name() {
  local target=$1
  basename "$target"
}

detect_state() {
  local source=$1
  local target=$2
  local mode=$3

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    printf 'not_installed'
    return
  fi

  if [ "$mode" = "symlink" ]; then
    if [ -L "$target" ]; then
      local link_target
      link_target="$(readlink -f "$target")"
      local expected
      expected="$(readlink -f "$source")"
      if [ "$link_target" = "$expected" ]; then
        printf 'installed_by_project'
      else
        printf 'existing_symlink'
      fi
    else
      printf 'user_config'
    fi
    return
  fi

  if [ -L "$target" ]; then
    printf 'existing_symlink'
    return
  fi

  if manifest_has_target "$target"; then
    local expected_checksum
    expected_checksum="$(manifest_get_checksum "$target")"
    local current_checksum
    current_checksum="$(generate_checksum "$target")"
    if [ "$current_checksum" = "$expected_checksum" ]; then
      printf 'installed_by_project'
    else
      printf 'modified'
    fi
    return
  fi

  printf 'user_config'
}

detect_all() {
  local script_dir=$1
  local mode=$2
  local mappings
  mappings="$(get_config_mappings "$script_dir")"

  while IFS= read -r mapping; do
    local source="${mapping%%|*}"
    local target="${mapping#*|}"
    local state
    state="$(detect_state "$source" "$target" "$mode")"
    local name
    name="$(target_name "$target")"
    printf '%s|%s|%s|%s|%s\n' "$name" "$source" "$target" "$state" "$mapping"
  done <<< "$mappings"
}

print_detection_summary() {
  local detections=$1

  printf '\nDetected configuration:\n\n'

  while IFS='|' read -r name source target state mapping; do
    case "$state" in
      not_installed)
        printf '  - %-16s (not installed)\n' "$name"
        ;;
      installed_by_project)
        printf '  + %-16s (already installed)\n' "$name"
        ;;
      user_config)
        printf '  ! %-16s (existing user config)\n' "$name"
        ;;
      existing_symlink)
        printf '  ~ %-16s (existing symlink)\n' "$name"
        ;;
      modified)
        printf '  * %-16s (modified installation)\n' "$name"
        ;;
      *)
        printf '  ? %-16s (unknown state)\n' "$name"
        ;;
    esac
  done <<< "$detections"

  printf '\n'
}

has_existing_configs() {
  local detections=$1

  while IFS='|' read -r name source target state mapping; do
    case "$state" in
      user_config|existing_symlink|modified)
        return 0
        ;;
    esac
  done <<< "$detections"

  return 1
}

show_interactive_menu() {
  printf 'Existing configurations detected.\n'
  printf 'Select an action:\n\n'
  printf '  1) Backup and overwrite (recommended)\n'
  printf '  2) Skip existing configurations\n'
  printf '  3) Replace only configurations previously installed by this project\n'
  printf '  4) Cancel installation\n\n'
  printf 'Choice [1]: '

  local choice
  read -r choice
  choice="${choice:-1}"

  case "$choice" in
    1) printf 'backup_and_overwrite' ;;
    2) printf 'skip_existing' ;;
    3) printf 'replace_project_only' ;;
    4) printf 'cancel' ;;
    *) printf 'backup_and_overwrite' ;;
  esac
}

should_install() {
  local state=$1
  local action=$2

  case "$state" in
    installed_by_project)
      return 1
      ;;
  esac

  case "$action" in
    backup_and_overwrite|force)
      case "$state" in
        not_installed|user_config|existing_symlink|modified)
          return 0
          ;;
      esac
      ;;
    skip_existing)
      case "$state" in
        not_installed)
          return 0
          ;;
      esac
      ;;
    replace_project_only)
      case "$state" in
        not_installed|modified)
          return 0
          ;;
      esac
      ;;
  esac

  return 1
}

should_backup() {
  local state=$1
  local action=$2

  case "$state" in
    installed_by_project|not_installed)
      return 1
      ;;
  esac

  case "$action" in
    backup_and_overwrite|force)
      case "$state" in
        user_config|existing_symlink|modified)
          return 0
          ;;
      esac
      ;;
    replace_project_only)
      case "$state" in
        modified)
          return 0
          ;;
      esac
      ;;
  esac

  return 1
}

print_plan() {
  local detections=$1
  local action=$2
  local dry_run=$3

  local -a will_install=()
  local -a will_skip=()
  local -a will_backup=()
  local -a will_replace=()
  local -a up_to_date=()

  while IFS='|' read -r name source target state mapping; do
    if [ "$state" = "installed_by_project" ]; then
      up_to_date+=("$name")
      continue
    fi
    if should_install "$state" "$action"; then
      case "$state" in
        not_installed)
          will_install+=("$name")
          ;;
        user_config|existing_symlink|modified)
          will_install+=("$name")
          will_replace+=("$name")
          ;;
      esac
      if should_backup "$state" "$action"; then
        will_backup+=("$name")
      fi
    else
      will_skip+=("$name")
    fi
  done <<< "$detections"

  if [ "$dry_run" = "true" ]; then
    printf '\n[dry-run] Installation plan:\n\n'
  else
    printf '\nInstallation plan:\n\n'
  fi

  if [ ${#will_install[@]} -gt 0 ]; then
    printf '  Will install:  %s\n' "${will_install[*]}"
  fi
  if [ ${#will_replace[@]} -gt 0 ]; then
    printf '  Will replace:  %s\n' "${will_replace[*]}"
  fi
  if [ ${#will_backup[@]} -gt 0 ]; then
    printf '  Will backup:   %s\n' "${will_backup[*]}"
  fi
  if [ ${#will_skip[@]} -gt 0 ]; then
    printf '  Will skip:     %s\n' "${will_skip[*]}"
  fi
  if [ ${#up_to_date[@]} -gt 0 ]; then
    printf '  Up to date:    %s\n' "${up_to_date[*]}"
  fi

  printf '\n'
}

deploy_copy() {
  local source=$1
  local target=$2
  local dry_run=$3

  if [ "$dry_run" = "true" ]; then
    printf '  [dry-run] copy: %s -> %s\n' "$(basename "$source")" "$target"
    return 0
  fi

  mkdir -p "$(dirname "$target")"

  if [ -e "$target" ] || [ -L "$target" ]; then
    safe_remove "$target"
  fi

  cp -a "$source" "$target"
  printf '  installed: %s\n' "$(target_name "$target")"
}

deploy_symlink() {
  local source=$1
  local target=$2
  local dry_run=$3

  if [ "$dry_run" = "true" ]; then
    printf '  [dry-run] link: %s -> %s\n' "$target" "$source"
    return 0
  fi

  mkdir -p "$(dirname "$target")"

  if [ -e "$target" ] || [ -L "$target" ]; then
    safe_remove "$target"
  fi

  ln -s "$source" "$target"
  printf '  linked: %s\n' "$(target_name "$target")"
}

print_post_summary() {
  local installed=$1
  local skipped=$2
  local backed_up=$3
  local failed=$4
  local dry_run=$5

  printf '\n'
  if [ "$dry_run" = "true" ]; then
    printf '[dry-run] Summary:\n'
  else
    printf 'Summary:\n'
  fi

  if [ "$installed" -gt 0 ]; then
    printf '  + %d installed\n' "$installed"
  fi
  if [ "$skipped" -gt 0 ]; then
    printf '  - %d skipped\n' "$skipped"
  fi
  if [ "$backed_up" -gt 0 ]; then
    printf '  ~ %d backed up\n' "$backed_up"
  fi
  if [ "$failed" -gt 0 ]; then
    printf '  ! %d failed\n' "$failed"
  fi

  if [ "$installed" -eq 0 ] && [ "$skipped" -eq 0 ] && [ "$failed" -eq 0 ]; then
    printf '  already up to date\n'
  fi
}
