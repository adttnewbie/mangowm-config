# Installation

## Quick Start

```bash
git clone https://github.com/ilyamiro/mangowm-config.git
cd mangowm-config
./install/install.sh
```

> [!WARNING]
> Do not run the installer as root.

The default mode is **copy**, which deploys configuration files independently
from the repository.

## Safety First

The installer prioritizes protecting your existing desktop configuration.

Before installing, it scans `~/.config` and classifies each managed component:

| State | Meaning |
| --- | --- |
| not installed | Target does not exist |
| already installed | Previously installed by this project, unchanged |
| existing user config | User's own configuration exists here |
| existing symlink | A symlink points elsewhere |
| modified installation | Installed by this project but since modified |

A summary is displayed before any action is taken:

```text
Detected configuration:

  ! mango            (existing user config)
  + kitty            (already installed)
  - rofi             (not installed)
  ~ nvim             (existing symlink)
```

## Interactive Mode

If existing configurations are detected, the installer presents an interactive
menu:

```text
Existing configurations detected.
Select an action:

  1) Backup and overwrite (recommended)
  2) Skip existing configurations
  3) Replace only configurations previously installed by this project
  4) Cancel installation

Choice [1]:
```

| Option | Behavior |
| --- | --- |
| 1 | Back up all existing configs, then install everything |
| 2 | Install only components that are not currently installed |
| 3 | Re-install only components previously installed by this project |
| 4 | Cancel without making any changes |

Option 1 is the default.

## Installation Modes

### Copy Mode (default)

```bash
./install/install.sh
./install/install.sh --copy
```

Recommended for normal users.

- Copies every configuration into `~/.config`
- Preserves permissions and timestamps
- Automatically creates missing directories
- Backs up existing configurations before overwriting
- Never deletes user files
- After installation, the configuration is completely independent from the
  repository

Copy mode uses a manifest file to track installed checksums. On re-run, it
detects unchanged configurations and skips them, avoiding unnecessary backups.

### Symlink Mode

```bash
./install/install.sh --symlink
```

Recommended for developers and contributors.

- Creates symbolic links instead of copying
- Backs up existing configurations before replacing them
- Safely replaces existing symlinks
- Never overwrites user files without backup
- Changes in the repository are immediately reflected in `~/.config`

Symlink mode checks each target on re-run. If a symlink already points to the
correct source, it is skipped.

### Differences

| Aspect | Copy | Symlink |
| --- | --- | --- |
| Target audience | End users | Developers |
| Config independence | Fully independent | Linked to repository |
| Updates | Re-run installer | Automatic (via git pull) |
| Disk usage | Duplicated | Shared |
| Customization safety | High (no repo impact) | Changes affect repo |

Both modes install the exact same desktop experience. Only the deployment
method differs.

## CLI Reference

```text
./install/install.sh [OPTIONS]

Options:
  --copy           Install by copying files (default)
  --symlink        Install by creating symlinks
  --force          Overwrite automatically after backup
  --skip-existing  Leave existing user configurations untouched
  --dry-run        Simulate installation without modifying files
  --restore        Restore from backup
  --uninstall      Remove installed configurations
  --skip-pkg       Skip package installation
  --plymouth       Install Plymouth theme
  --help           Show help
```

## Overwrite Policy

The installer never overwrites automatically unless:

- The user selected option 1 (backup and overwrite) in the interactive menu
- The user passed `--force`

Without explicit confirmation, the installer refuses to overwrite existing user
configurations and exits with an error.

## Force Mode

```bash
./install/install.sh --force
```

Skips the interactive menu and automatically backs up existing configurations
before overwriting. Intended for scripted or non-interactive use.

## Skip-Existing Mode

```bash
./install/install.sh --skip-existing
```

Installs only components that are not currently present. Existing user
configurations are left completely untouched. No backups are created for
skipped targets.

## Dry-Run Mode

```bash
./install/install.sh --dry-run
./install/install.sh --symlink --dry-run
```

Simulates the installation without modifying any files. Displays what would be
installed, skipped, backed up, or replaced. Useful for previewing changes
before committing to them.

## Backup System

Before modifying any configuration, the installer creates a timestamped backup:

```text
~/.config-backup/YYYYMMDD-HHMMSS/
```

Each backup contains the full contents of every replaced configuration target.
Backups preserve file permissions and symlinks.

Backups are only created for targets that will actually be modified. Targets
that are already up to date or will be skipped are not backed up.

## Restore Process

Restore the latest backup:

```bash
./install/install.sh --restore
```

List available backups:

```bash
./install/restore.sh --list
```

Restore a specific backup by number:

```bash
./install/restore.sh 1
```

## Uninstall

Remove all installed configurations:

```bash
./install/install.sh --uninstall
```

A backup is automatically created before removal. Use `--restore` to recover.

## Idempotency

Running the installer multiple times is safe:

- Already-installed configurations (unchanged) are detected and skipped
- No duplicate backups are created for unchanged targets
- No files are overwritten if checksums match
- The manifest tracks installation state for copy mode
- Symlink mode checks link targets directly

## Installed Targets

| Source | Target |
| --- | --- |
| `config/sessions/mango` | `~/.config/mango` |
| `config/programs/kitty` | `~/.config/kitty` |
| `config/programs/rofi` | `~/.config/rofi` |
| `config/programs/cava` | `~/.config/cava` |
| `config/programs/neovim` | `~/.config/nvim` |
| `config/programs/zsh` | `~/.config/zsh` |
| `config/programs/matugen` | `~/.config/matugen` |
| `quickshell` | `~/.config/quickshell` |
| `scripts` | `~/.local/share/mango/scripts` |

## Recommended Usage

- **First-time users**: run `./install/install.sh` (copy mode)
- **Developers**: run `./install/install.sh --symlink` for live editing
- **Preview changes**: run `./install/install.sh --dry-run` first
- **After updates (copy mode)**: re-run `./install/install.sh` to refresh
- **After updates (symlink mode)**: `git pull` is sufficient
- **Preserve custom configs**: run `./install/install.sh --skip-existing`
- **Scripted installs**: run `./install/install.sh --force`
- **If something breaks**: run `./install/install.sh --restore`
