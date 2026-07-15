# Migration to Arch Linux + MangoWM

## Purpose

This repository is becoming a native Arch Linux + MangoWM desktop
configuration inspired by ilyamiro's original desktop. It is not a NixOS or
Hyprland compatibility layer. MangoWM behavior takes priority over exact
Hyprland feature parity.

`docs/architecture.md` defines the target layout, ownership boundaries, and
installation flow. This document is the canonical record of migration status
and intentional behavior changes.

## Audit

### NixOS-specific files

These files are not part of the Arch installation and are retained only until
their reusable content has a tested replacement:

- `configuration.nix` — NixOS packages, services, boot, hardware, users, and
  system settings.
- `hardware-configuration.nix` — host-specific NixOS hardware declaration.
- `home.nix` — Home Manager imports, package definitions, file deployment, and
  desktop settings.
- `config/programs/cava/default.nix`
- `config/programs/kitty/default.nix`
- `config/programs/matugen/default.nix`
- `config/programs/neovim/default.nix`
- `config/programs/plymouth/default.nix`
- `config/programs/rofi/default.nix`
- `config/programs/swayosd/default.nix`
- `config/programs/zsh/default.nix`
- `config/sessions/hyprland/default.nix`
- `config/sessions/hyprland/hypridle.nix`
- `config/sessions/hyprland/scripts/quickshell/calendar/schedule/shell.nix`

The following files are otherwise reusable but contain Nix-specific values and
need targeted edits:

- `README.md` — current NixOS-oriented installation guidance.
- `config/programs/plymouth/simple/simple.plymouth` — `@out@` store-path
  substitution.
- `config/programs/zsh/zsh-init.sh` — NixOS aliases, `nix develop`, and a
  NixOS Fastfetch logo.
- `config/sessions/hyprland/config/env.conf` — `NIXOS_OZONE_WL`.
- `config/sessions/hyprland/scripts/quickshell/applauncher/app_fetcher.py` —
  `/run/current-system` application path.
- `config/sessions/hyprland/scripts/quickshell/calendar/schedule/schedule_manager.sh`
  — Nix development shell launcher.
- `config/sessions/hyprland/scripts/quickshell/wallpaper/WallpaperPicker.qml`
  — `/run/current-system` executable path.

### Reusable components

These retain their content where possible. Their placement or a path reference
may change, but they do not need a Nix-to-Arch rewrite.

- `config/fonts/` font assets.
- `previews/` screenshots.
- `config/programs/*` application config files and Matugen templates, except
  the Mango color template that replaces the Hyprland template.
- Plymouth image resources and theme artwork.
- Most QuickShell widgets, images, sounds, Python helpers, and shell helpers.
- Audio, battery, Bluetooth, network, clipboard, calendar, music, QR, and
  wallpaper logic that uses standard Wayland or user-session tools.

### Compositor-dependent components

The current Hyprland session config and these consumers require native Mango
implementations:

- Hyprland config fragments, rules, animations, bindings, and monitor config.
- `hyprctl` calls in session scripts and QuickShell UI.
- Hyprland event-socket consumers in workspace and keyboard watchers.
- Hyprland workspace model, including the former workspace `10`.
- Runtime monitor configuration and wallpaper monitor discovery.
- Hyprland-specific layer/window rules and submap behavior.

## Target migration phases

1. Publish this specification and `docs/architecture.md`.
2. Add Arch/Mango-native files without activating or deleting legacy Nix files.
3. Add package lists and idempotent installation scripts.
4. Port the Mango config, startup sequence, and compositor service.
5. Route QuickShell through the compositor service and migrate the affected UI.
6. Validate every replacement, then remove obsolete Nix files and references.
7. Rewrite the README and final support documentation.

No legacy Nix file is removed before its reusable content is either preserved,
replaced, or explicitly documented as intentionally dropped.

## Behavior changes

| Previous behavior | Arch + MangoWM behavior | Status |
| --- | --- | --- |
| NixOS and Home Manager deploy configuration | `install/` links standard XDG paths on Arch | Planned |
| Hyprland workspaces `1`–`10` | MangoWM tags `1`–`9` | Approved |
| `hyprctl` and Hyprland socket | `mmsg` and MangoWM tag/monitor state | Planned |
| Hyprland config reload | MangoWM `reload_config` | Planned |
| Hyprland monitor keyword updates | Mango `monitorrule`; runtime output changes via `wlr-randr` | Planned |
| `hypridle` | `swayidle` driving the existing QuickShell lock UI | Planned |
| Nix store and `/run/current-system` lookup | standard XDG directories and normal Arch `PATH` lookup | Planned |
| Nix-based `stsetup` project helper | removed; it depends on a project-specific Nix shell | Planned |
| NixOS Fastfetch logo | Arch Linux logo | Planned |

## Implementation status

| Phase | Status |
| --- | --- |
| 1. Documentation and audit | Complete |
| 2. Mango-owned skeleton | Complete |
| 3. Canonical package manifests | Complete |
| 4. Safe installation scripts | Complete |
| 5. Native MangoWM configuration | Complete |
| 6. Mango compositor service | Complete |
| 7. QuickShell and portable scripts | Complete |
| 8. Obsolete Nix and Hyprland removal | Complete |
| 9. Final validation and maintenance docs | Complete |

## Compatibility rules

- `config/programs/` and unchanged application config filenames remain close to
  upstream.
- Mango-only behavior belongs in `config/sessions/mango/`, `scripts/mango/`,
  or `quickshell/services/mango/`.
- Generic QuickShell components must not invoke `mmsg` directly.
- Installation never references a Nix path, Home Manager, flake, or Nix
  package.
- The final active configuration has no NixOS dependency. Legacy files are
  removed only in the cleanup phase.

## Known limitations

### Startup and portals

- XDG Desktop Portal selection is not configured by this repository. Users must
  ensure `xdg-desktop-portal-wlr` or another appropriate backend is installed
  and configured for their environment.

### Monitor identification

- Monitor names and positions are host-specific. Users must edit
  `~/.config/mango/conf.d/monitors.conf` to match their hardware. Use
  `wlr-randr` or `wayland-info` to discover monitor names.

### QuickShell

- QuickShell requires `quickshell-git` from AUR. The stable release may not
  include required features.
- Some widgets assume specific font families (Inter, JetBrains Mono, Font
  Awesome). Missing fonts will cause rendering issues.

### Lock and idle

- `swayidle` and `swaylock` are configured for MangoWM. Idle timeouts and lock
  commands can be adjusted in `~/.config/mango/conf.d/autostart.conf`.

### Wallpapers

- `swww` is the wallpaper daemon. Use `swww img /path/to/image` to change
  wallpapers, or use the QuickShell wallpaper picker.
- Matugen generates colors from wallpapers. Run `matugen image /path/to/wallpaper.png`
  to regenerate the color scheme.

### AUR helper failures

- If AUR package installation fails, check that your AUR helper is up to date
  and that your system is fully updated (`sudo pacman -Syu`).
- Some AUR packages may require manual intervention or have build dependencies
  that need to be installed first.

### Native redesigns

- Workspace navigation uses tags 1-9 only (no workspace 10).
- `bind` syntax is used for keybindings (not `bindm` for mouse).
- Mouse bindings use `mousebind` keyword.
- Workspace commands use `view` and `tag` (not `workspace` and `movetoworkspace`).
- IPC uses `mmsg` (not `hyprctl`).

## Maintenance procedures

### Running tests

Before committing changes, run the test suite:

```bash
bash scripts/test-install.sh
```

This validates:
- Symlink creation and integrity
- Mango config syntax
- Portability (no Hyprland/Nix references in active code)
- Shell script syntax

### Adding new packages

1. Add official packages to `packages-pacman.txt`
2. Add AUR packages to `packages-aur.txt`
3. Update `docs/packages.md` with package description and group
4. Run `./install/packages.sh` to verify installation

### Updating MangoWM configuration

1. Edit files in `config/sessions/mango/conf.d/`
2. Test with `mango -c config/sessions/mango/config.conf -p`
3. Restart Mango session to apply changes

### Updating QuickShell

1. Edit QML files in `quickshell/`
2. Mango-only changes belong in `quickshell/services/mango/`
3. Test with `quickshell` (requires running Mango session)
4. Run `bash scripts/test-portability.sh` to ensure no Hyprland references

### Upstream synchronization

1. Fetch upstream changes: `git fetch upstream`
2. Review changes before merging: `git diff HEAD upstream/main`
3. Merge with minimal local edits to upstream-owned paths
4. Resolve conflicts in Mango-owned paths only
5. Run `bash scripts/test-install.sh` after resolving
6. Document behavior changes in this file
