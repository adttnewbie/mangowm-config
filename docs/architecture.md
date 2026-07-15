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

Each installer is safe to run independently:

- `install/packages.sh` installs package manifests.
- `install/link.sh` links configuration into standard XDG paths.
- `install/fonts.sh` installs or links local fonts and refreshes fontconfig.
- `install/themes.sh` installs or links theme assets, including the optional
  system Plymouth theme.
- `install/install.sh` calls the preceding scripts in that order.

All scripts are idempotent. Before replacing an existing non-symlink target,
`link.sh` creates a timestamped backup and refuses destructive overwrites on
failure. Re-running the installer preserves a working link, refreshes changed
links, and never removes user files without a backup.

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
