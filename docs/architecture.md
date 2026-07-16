# Architecture

## Identity

This is the reference desktop configuration for Arch Linux + MangoWM, inspired
by ilyamiro's original desktop. It is neither a Hyprland fork nor a compositor
compatibility layer. Native MangoWM behavior is the source of truth.

## Repository layout

```text
config/
  fonts/                    upstream-owned font assets
  programs/                 upstream-owned application configuration sources
  sessions/
    hyprland/               temporary legacy reference; never installed
    mango/                  Mango-owned config.conf and source fragments
quickshell/
  services/mango/           Mango-owned compositor service implementation
scripts/
  mango/                    Mango-owned command and IPC implementations
install/                    independent Arch installation scripts
  install.sh                  orchestrator with CLI and interactive safety
  copy.sh                     copy installation mode
  symlink.sh                  symlink installation mode
  backup.sh                   shared detection, backup, reporting, and deploy
  restore.sh                  restore from backups
  uninstall.sh                remove installed configurations
  packages.sh                 pacman and AUR package installation
  fonts.sh                    font installation
  themes.sh                   Plymouth theme installation
  test-link.sh                integration tests for both modes and safety
docs/                       user and maintainer documentation
previews/                   upstream-owned screenshots
```

The existing `config/programs/` hierarchy and unchanged filenames are retained
whenever practical. New Mango-only code is isolated instead of being spread
through upstream-compatible assets.

## Ownership and generated data

| Category | Location | Update rule |
| --- | --- | --- |
| Upstream-owned | `config/fonts/`, `config/programs/`, `previews/`, reusable QuickShell widgets | Merge upstream changes first; avoid cosmetic edits. |
| Mango-owned | `config/sessions/mango/`, `scripts/mango/`, `quickshell/services/mango/` | Maintain locally against MangoWM's documented interfaces. |
| Generated | Matugen output, QuickShell cache/state/run files, thumbnails | Never commit; recreate from configuration. |
| User-customizable | monitor overrides, wallpapers, application paths, local settings | Keep outside tracked defaults or provide an ignored local override. |

## Startup sequence

1. A display manager or TTY starts `mango`.
2. Mango loads `~/.config/mango/config.conf`, which sources modular fragments.
3. Mango applies environment, input, monitor, visual, rules, and native tag
   bindings.
4. `exec-once` starts the wallpaper daemon, `swayidle`, clipboard watchers,
   audio helpers, and QuickShell.
5. QuickShell starts its Mango compositor service and generic UI components.
6. The service watches Mango state and publishes normalized tag, monitor,
   keyboard, and active-client data to the UI.

The configuration uses Mango `source`, `monitorrule`, native tag dispatchers,
and `mmsg`; it never starts Hyprland or calls `hyprctl`.

## QuickShell architecture

QuickShell is a portable visual shell: notifications, widgets, popups, media,
network, battery, calendar, and theme rendering remain independent of the
compositor. Components receive state and actions from a service rather than
constructing compositor commands themselves.

`quickshell/services/mango/` is the only QML layer allowed to know MangoWM.
It exposes operations such as:

- `viewTag(tag)` and `moveFocusedClientToTag(tag)`.
- `watchTags()` and `watchActiveClient()`.
- `getMonitors()` and monitor power/configuration operations.
- `switchKeyboardLayout()`.
- `reloadConfig()` and `quitSession()`.

UI components must not invoke `mmsg` directly. Components that need an action
call the injected service API. Components that need state consume its normalized
properties or data files. This keeps all Mango-specific changes contained.

## Compositor command layer

`scripts/mango/` contains idempotent executable boundaries for MangoWM and
Wayland actions. It owns the direct use of `mmsg`, `wlr-randr`, and any
Mango-specific environment. QuickShell services call these scripts when a
shell-based bridge is safer than embedding command construction in QML.

The command layer covers tag state, monitor data, keyboard layout, session
control, screen capture, wallpaper application, and lock/idle integration.
It returns stable JSON or exit status to the service; UI code does not parse
Mango IPC output.

## Package management

`packages-pacman.txt` and `packages-aur.txt` are the canonical, line-oriented
package manifests. `install/packages.sh` reads them and installs official
packages with `pacman` and AUR packages only through an available AUR helper.
`docs/packages.md` explains every package group and optional dependency.

## Installation flow

The installer supports two deployment modes:

- **Copy mode** (default): copies configuration files to `~/.config`, making
  them independent from the repository. Recommended for end users.
- **Symlink mode**: creates symbolic links to the repository. Recommended for
  developers and contributors.

`install/install.sh` orchestrates the full installation and accepts `--copy`,
`--symlink`, `--force`, `--skip-existing`, `--dry-run`, `--restore`, and
`--uninstall` flags. When no flag is provided, it defaults to `--copy`.

The installer prioritizes protecting existing user configurations. Before
installing, it scans all managed targets and classifies their state (not
installed, already installed, existing user config, existing symlink, or
modified). If existing configurations are detected, an interactive menu is
presented. The `--force` flag bypasses the menu for scripted use; `--dry-run`
simulates without modifying files.

Each sub-script is safe to run independently:

- `install/backup.sh` provides shared detection, backup, reporting, and deploy
  functions used by all other scripts.
- `install/copy.sh` deploys configuration by copying.
- `install/symlink.sh` deploys configuration by symlinking.
- `install/packages.sh` installs package manifests.
- `install/fonts.sh` installs local fonts and refreshes fontconfig.
- `install/themes.sh` installs theme assets, including the optional Plymouth theme.
- `install/restore.sh` restores configurations from backups.
- `install/uninstall.sh` removes installed configurations.
- `install/test-link.sh` runs integration tests for both modes, skip-existing,
  and dry-run behavior.

All scripts are idempotent. A manifest file tracks installation state for copy
mode; symlink mode checks link targets directly. Before modifying any existing
target, the installer creates a timestamped backup under
`~/.config-backup/YYYYMMDD-HHMMSS/`. Re-running the installer detects an
up-to-date installation and skips unnecessary work. User files are never
removed without a backup and explicit confirmation.

## Update and upstream synchronization strategy

1. Fetch and inspect upstream changes before merging.
2. Merge upstream-owned paths with minimal local edits.
3. Keep Mango-owned paths in the isolated locations above; resolve only their
   explicit integration points after an upstream merge.
4. Do not merge generated files or local overrides.
5. Run the targeted config/service validation after resolving conflicts.
6. Record an upstream-impacting decision in `MIGRATION.md` when it changes
   visible behavior or ownership.

Avoid formatting-only commits and unnecessary moves. Use focused commits by
migration phase so an upstream change can be compared, reverted, or
cherry-picked without a repository-wide rewrite.
