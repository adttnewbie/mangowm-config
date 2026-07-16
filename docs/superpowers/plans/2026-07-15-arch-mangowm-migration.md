# Arch Linux + MangoWM Migration Implementation Plan

> **Status: Complete** — This plan has been fully executed. All tasks below are historical.
> The canonical migration record is [`MIGRATION.md`](../../../MIGRATION.md).

> For agentic workers: use superpowers:executing-plans task by task. Steps use checkboxes for tracking.

**Goal:** Convert this repository into a standalone Arch Linux + MangoWM desktop configuration while retaining upstream-friendly reusable content.

**Architecture:** Keep upstream-compatible application configuration under config/. Place MangoWM code only in config/sessions/mango/, scripts/mango/, and quickshell/services/mango/. QuickShell receives compositor state and actions only through the Mango service.

**Tech Stack:** Arch Linux, pacman, AUR helper, MangoWM, mmsg, QuickShell/QML, Bash, Python, swayidle, swww, PipeWire.

## Global Constraints

- Active files cannot reference NixOS, Home Manager, flakes, /nix/store, /run/current-system, or hyprctl.
- Use MangoWM tags 1 through 9; do not emulate workspace 10.
- UI QML outside quickshell/services/mango/ must not invoke mmsg.
- Preserve config/programs/ paths and unchanged filenames where no Mango-specific change is required.
- Every installer is idempotent; a non-symlink user target is backed up before replacement.
- Each task is a focused commit. Do not include formatting-only edits.
- After every task verify config syntax, shell syntax, links, package manifests, and Nix-runtime absence applicable to that task. Record any unavoidable temporary regression in MIGRATION.md.

---

### Task 1: Commit Approved Specifications

**Files:**
- Add: MIGRATION.md
- Add: docs/migration.md
- Add: docs/architecture.md
- Add: docs/superpowers/plans/2026-07-15-arch-mangowm-migration.md

**Produces:** canonical migration status, architecture contract, and execution plan.

- [ ] Verify: git diff --check
- [ ] Verify: for file in $(git ls-files '*.nix'); do rg -Fq "$file" MIGRATION.md || printf 'missing: %s\n' "$file"; done
- [ ] Expected: no output from the inventory check.
- [ ] Commit:
  git add MIGRATION.md docs/migration.md docs/architecture.md docs/superpowers/plans/2026-07-15-arch-mangowm-migration.md
  git commit -m "docs: define Arch MangoWM migration"

### Task 2: Create the Mango-Owned Skeleton

**Files:**
- Create: config/sessions/mango/config.conf
- Create: config/sessions/mango/conf.d/{autostart,bindings,environment,input,monitors,rules,theme}.conf
- Create: config/sessions/mango/conf.d/local.conf.example
- Create: scripts/mango/ipc.sh
- Create: scripts/mango/test-ipc-contract.sh
- Create: quickshell/services/mango/README.md
- Modify: .gitignore
- Modify: MIGRATION.md

**Interfaces:**
- scripts/mango/ipc.sh action argument
- Actions: view-tag, move-to-tag, tags, monitors, keyboard-layout, switch-keyboard-layout, reload, quit.
- Query actions write JSON; mutating actions return Mango's exit status.

- [ ] Write scripts/mango/test-ipc-contract.sh to require every action and reject any tag outside 1-9.
- [ ] Run bash scripts/mango/test-ipc-contract.sh; expect failure because ipc.sh is absent.
- [ ] Implement config.conf with exactly these source entries:
  source=./conf.d/environment.conf
  source=./conf.d/monitors.conf
  source=./conf.d/input.conf
  source=./conf.d/theme.conf
  source=./conf.d/rules.conf
  source=./conf.d/bindings.conf
  source=./conf.d/autostart.conf
- [ ] Implement ipc.sh with set -eu and a case validation branch: [1-9] accepts a tag and all other values exit 64.
- [ ] Verify: bash -n scripts/mango/ipc.sh scripts/mango/test-ipc-contract.sh
- [ ] Verify: mango -c config/sessions/mango/config.conf -p
- [ ] Commit:
  git add .gitignore MIGRATION.md config/sessions/mango scripts/mango quickshell/services/mango/README.md
  git commit -m "feat: add Mango configuration skeleton"

### Task 3: Add Canonical Package Manifests

**Files:**
- Create: packages-pacman.txt
- Create: packages-aur.txt
- Create: docs/packages.md
- Modify: MIGRATION.md

**Interfaces:**
- One package per non-comment line.
- packages-pacman.txt contains official Arch packages only.
- packages-aur.txt contains AUR packages only and no AUR helper package.

- [ ] Derive command candidates with:
  rg -o --glob '!*.nix' --glob '!*.qml' '\b[a-z][a-z0-9-]{2,}\b' config scripts quickshell 2>/dev/null | sort -u > /tmp/mango-command-candidates
- [ ] Classify every runtime dependency from current package declarations and command use.
- [ ] Verify official package names on Arch with pacman -Si before putting them in packages-pacman.txt.
- [ ] Put mangowm-git and the selected QuickShell package in packages-aur.txt.
- [ ] Document package groups, optional dependencies, and the required AUR-helper behavior in docs/packages.md.
- [ ] Verify:
  awk 'NF && $1 !~ /^#/ { if ($1 !~ /^[a-z0-9@._+:-]+$/) exit 1 }' packages-pacman.txt packages-aur.txt
  comm -12 <(sed '/^\s*#/d;/^\s*$/d' packages-pacman.txt | sort) <(sed '/^\s*#/d;/^\s*$/d' packages-aur.txt | sort) | (! read)
- [ ] Commit:
  git add packages-pacman.txt packages-aur.txt docs/packages.md MIGRATION.md
  git commit -m "feat: add Arch package manifests"

### Task 4: Implement Safe Installation Scripts

**Files:**
- Create: install/packages.sh
- Create: install/link.sh
- Create: install/fonts.sh
- Create: install/themes.sh
- Create: install/install.sh
- Create: install/test-link.sh
- Modify: .gitignore
- Modify: docs/architecture.md
- Modify: docs/packages.md

**Interfaces:**
- packages.sh accepts --pacman-only and --aur-only.
- link.sh accepts --dry-run and creates target.bak-YYYYmmddHHMMSS before replacing a regular target.
- fonts.sh refreshes fontconfig.
- themes.sh accepts --plymouth for the optional system theme.
- install.sh runs package, link, font, then theme installers.

- [ ] Write install/test-link.sh: create a temporary XDG_CONFIG_HOME, write a conflicting regular file, run link.sh, then assert one backup and one valid symlink.
- [ ] Run bash install/test-link.sh; expect failure because link.sh is absent.
- [ ] Implement one replacement helper:
  link_target() {
    source=$1
    target=$2
    [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ] && return
    [ -e "$target" ] || [ -L "$target" ] && mv "$target" "$target.bak-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
  }
- [ ] Derive repository paths from each script's own directory. Do not hard-code a user home directory.
- [ ] Verify:
  bash -n install/*.sh
  bash install/test-link.sh
  tmp=$(mktemp -d); XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" bash install/link.sh; XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" bash install/link.sh
  find "$tmp" -xtype l -print -quit | (! read)
- [ ] Commit:
  git add install .gitignore docs/architecture.md docs/packages.md
  git commit -m "feat: add safe Arch installer"

### Task 5: Implement Native MangoWM Configuration

**Files:**
- Modify: config/sessions/mango/config.conf
- Modify: config/sessions/mango/conf.d/{autostart,bindings,environment,input,monitors,rules,theme}.conf
- Create: config/sessions/mango/conf.d/colors.conf
- Modify: config/programs/matugen/config.toml
- Create: config/programs/matugen/templates/mango.conf.template
- Create: config/sessions/mango/test-config.sh
- Modify: MIGRATION.md

**Interfaces:**
- config.conf starts QuickShell, swww, swayidle, clipboard watchers, and existing audio helpers.
- Native bindings use view,1 through view,9 and tag,1 through tag,9.
- local.conf is optional and ignored.

- [ ] Write test-config.sh to require bind=SUPER,1,view,1 and reject hyprctl, NIXOS_OZONE_WL, and unavailable exec-once paths.
- [ ] Run bash config/sessions/mango/test-config.sh; expect failure until the config is implemented.
- [ ] Use monitorrule=name:^eDP-1$,width:1920,height:1080,refresh:144,x:0,y:0,scale:1 as the default monitor.
- [ ] Port input to xkb_rules_layout=us,ru, xkb_rules_options=grp:alt_shift_toggle, flat pointer acceleration, and natural touchpad scrolling.
- [ ] Use Mango dispatchers for focus, movement, floating, fullscreen, tags, and reload_config.
- [ ] Replace the Hyprland Matugen template with a Mango color template.
- [ ] Verify:
  bash config/sessions/mango/test-config.sh
  mango -c config/sessions/mango/config.conf -p
  ! rg -n '(hyprctl|HYPRLAND|NIXOS_OZONE_WL|/run/current-system|/nix/store)' config/sessions/mango config/programs/matugen
- [ ] Commit:
  git add config/sessions/mango config/programs/matugen MIGRATION.md .gitignore
  git commit -m "feat: configure native MangoWM session"

### Task 6: Implement the Mango Compositor Service

**Files:**
- Modify: scripts/mango/ipc.sh
- Create: scripts/mango/{tags,monitors,keyboard,session,test-ipc}.sh
- Create: quickshell/services/mango/{MangoService,MangoState}.qml
- Create: quickshell/services/mango/qmldir
- Modify: docs/architecture.md

**Interfaces:**
- MangoService.qml exposes viewTag(tag), moveFocusedClientToTag(tag), reloadConfig(), quitSession(), and switchKeyboardLayout().
- MangoState.qml exposes tags, monitors, activeClient, and keyboardLayout.
- No QML outside quickshell/services/mango/ contains mmsg.

- [ ] Write test-ipc.sh with a fake mmsg in PATH. Assert view-tag 0 exits 64, view-tag 1 invokes mmsg dispatch view,1, and tags invokes an mmsg get query.
- [ ] Run bash scripts/mango/test-ipc.sh; expect failure until the command APIs exist.
- [ ] Make MangoService.qml call scripts/mango only; it must never build an mmsg command.
- [ ] Make MangoState.qml normalize Mango tags to a fixed 1-9 list.
- [ ] Verify:
  bash -n scripts/mango/*.sh
  bash scripts/mango/test-ipc.sh
  rg -n 'mmsg' quickshell --glob '*.qml' | rg -v '^quickshell/services/mango/'
- [ ] Expected: final rg command has no output.
- [ ] Commit:
  git add scripts/mango quickshell/services/mango docs/architecture.md
  git commit -m "feat: add Mango compositor service"

### Task 7: Migrate QuickShell and Portable Scripts

**Files:**
- Move: config/sessions/hyprland/scripts/quickshell/ to quickshell/
- Move: config/sessions/hyprland/scripts/{caching,exit,lock,qs_manager,reload,screenshot,volume_listener,workspaces}.sh to scripts/
- Modify: quickshell/{Shell,Main,TopBar,Config,Scaler,ScreenshotOverlay}.qml
- Modify: affected QML files with an old compositor path or direct action
- Modify: scripts/{caching,exit,lock,qs_manager,reload,screenshot,workspaces}.sh
- Modify: config/programs/zsh/zsh-init.sh
- Modify: config/programs/plymouth/simple/simple.plymouth
- Create: scripts/test-portability.sh
- Modify: MIGRATION.md

**Interfaces:**
- Shell.qml injects MangoService into UI components.
- qs_manager.sh manages popup lifecycle only; tag and monitor actions delegate to scripts/mango/.
- Runtime paths use XDG variables or each script's resolved directory.

- [ ] Write test-portability.sh:
  #!/usr/bin/env bash
  set -eu
  ! rg -n '(~/.config/hypr|\.config/hypr|hyprctl|HYPRLAND_INSTANCE_SIGNATURE|/run/current-system|/etc/nixos|/home/ilyamiro)' quickshell scripts config/programs --glob '!*.nix'
  rg -l 'mmsg' quickshell --glob '*.qml' | grep -vx 'quickshell/services/mango/MangoState.qml' | grep -vx 'quickshell/services/mango/MangoService.qml' | (! read)
- [ ] Run bash scripts/test-portability.sh; expect failure before migration.
- [ ] Use git mv for retained QuickShell and helper files.
- [ ] Replace only compositor calls with service APIs or scripts/mango equivalents. Preserve widget appearance and non-compositor helper behavior.
- [ ] Replace desktop search with XDG_DATA_HOME/applications and /usr/share/applications.
- [ ] Remove Nix-only Zsh aliases, the stsetup helper, and the NixOS Fastfetch logo. Replace the Plymouth @out@ path with the Arch theme path.
- [ ] Verify:
  bash -n scripts/*.sh scripts/mango/*.sh
  bash scripts/test-portability.sh
- [ ] Commit:
  git add quickshell scripts config/programs/zsh/zsh-init.sh config/programs/plymouth/simple/simple.plymouth MIGRATION.md
  git commit -m "feat: migrate QuickShell to Mango service"

### Task 8: Remove Obsolete Nix and Hyprland Components

**Files:**
- Delete: configuration.nix
- Delete: hardware-configuration.nix
- Delete: home.nix
- Delete: all config/programs/**/default.nix
- Delete: config/sessions/hyprland/
- Modify: README.md
- Modify: .gitignore
- Modify: MIGRATION.md
- Create: docs/troubleshooting.md
- Create: scripts/test-no-nix.sh

**Interfaces:**
- Produces no active or tracked NixOS configuration surface.
- README uses install/install.sh and the standard Arch Mango session.

- [ ] Write test-no-nix.sh:
  #!/usr/bin/env bash
  set -eu
  test -z "$(git ls-files '*.nix')"
  ! rg -n -i '(home-manager|nixos|nixpkgs|/nix/store|/run/current-system|/etc/nixos|nix develop|nixos-rebuild)' --glob '!MIGRATION.md' --glob '!docs/migration.md' --glob '!docs/architecture.md' .
- [ ] Run bash scripts/test-no-nix.sh; expect failure while legacy files remain.
- [ ] Delete only modules audited in MIGRATION.md after confirming their portable content was moved or retired in Task 7.
- [ ] Rewrite README with goals, Arch support, Mango compatibility, installation, previews, troubleshooting, and native behavior changes.
- [ ] Verify:
  bash scripts/test-no-nix.sh
  test ! -e config/sessions/hyprland
  ! rg -n 'hyprland|hyprctl' README.md config quickshell scripts install packages-pacman.txt packages-aur.txt
- [ ] Commit:
  git add -A
  git commit -m "refactor: remove obsolete NixOS configuration"

### Task 9: Final Validation and Maintenance Documentation

**Files:**
- Modify: README.md
- Modify: MIGRATION.md
- Modify: docs/architecture.md
- Modify: docs/packages.md
- Modify: docs/troubleshooting.md
- Create: scripts/test-install.sh

**Interfaces:**
- test-install.sh runs all static checks in a temporary XDG home.
- Documentation records remaining limits and upstream synchronization guidance.

- [ ] Write test-install.sh to create a temporary XDG tree, invoke install/link.sh, check links with find -xtype l, parse Mango config, run portability and no-Nix checks, and run every shell syntax check.
- [ ] Run bash scripts/test-install.sh; expect exit 0.
- [ ] Document startup, portals, monitor identification, QuickShell, lock/idle, wallpapers, AUR helper failures, native redesigns, and known limitations.
- [ ] Commit:
  git add README.md MIGRATION.md docs scripts/test-install.sh
  git commit -m "docs: finalize Arch MangoWM migration"

