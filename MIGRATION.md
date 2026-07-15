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
| 6. Mango compositor service | Planned |
| 7. QuickShell and portable scripts | Planned |
| 8. Obsolete Nix and Hyprland removal | Planned |
| 9. Final validation and maintenance docs | Planned |

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
