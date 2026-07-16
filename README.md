[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/ilyamiro)

# Arch Linux + MangoWM Desktop Configuration

A native Arch Linux + MangoWM desktop configuration inspired by ilyamiro's
original desktop. This is not a Hyprland fork or compatibility layer — MangoWM
behavior is the source of truth.

## Requirements

- Arch Linux (or Arch-based distribution)
- Wayland session
- An AUR helper (yay or paru)

## Installation

```bash
git clone https://github.com/adttnewbie/mangowm-config.git
cd mangowm-config
./install/install.sh
```

> [!WARNING]
> DO NOT LAUNCH THIS AS ROOT!

The default installation mode is **copy**, which copies all configuration files
to `~/.config` so they are independent from this repository.

Before installing, the installer scans `~/.config` and displays a summary of
existing configurations. If user configurations are detected, an interactive
menu lets you choose how to proceed.

For development, use symlink mode:

```bash
./install/install.sh --symlink
```

Preview without modifying files:

```bash
./install/install.sh --dry-run
```

### CLI Options

| Option | Description |
| --- | --- |
| `--copy` | Copy files (default, recommended for users) |
| `--symlink` | Create symlinks (recommended for developers) |
| `--force` | Overwrite automatically after backup |
| `--skip-existing` | Leave existing user configurations untouched |
| `--dry-run` | Simulate installation without modifying files |
| `--restore` | Restore from the latest backup |
| `--uninstall` | Remove installed configurations |
| `--skip-pkg` | Skip package installation |
| `--plymouth` | Install Plymouth theme |

See [docs/installation.md](docs/installation.md) for full details.

The installer will:
1. Install required packages from official repos and AUR
2. Detect existing configurations and show a summary
3. Deploy configuration files (copy or symlink)
4. Install fonts
5. Optionally install Plymouth theme (with `--plymouth`)

After installation, log out and select "Mango" from your display manager.

## Features

- **MangoWM** — Tiling Wayland compositor with tag-based workspaces (1-9)
- **QuickShell** — QML-based panels, popups, and widgets
- **Matugen** — Material You color generation from wallpapers
- **swww** — Animated wallpaper daemon
- **swayidle/swaylock** — Idle management and screen locking

## Documentation

- [Installation](docs/installation.md) — Installation modes, backup, and restore
- [Architecture](docs/architecture.md) — Repository layout and ownership
- [Packages](docs/packages.md) — Package lists and installation
- [Migration](MIGRATION.md) — Migration status and behavior changes

## Previews

![preview1](previews/screenshot1.png)
![preview2](previews/screenshot2.png)
![preview3](previews/screenshot3.png)
![preview4](previews/screenshot4.png)
![preview5](previews/screenshot5.png)
![preview6](previews/screenshot6.png)
![preview7](previews/screenshot7.png)
![preview8](previews/screenshot8.png)
![preview9](previews/screenshot9.png)
![preview10](previews/screenshot10.png)

## Wallpapers

You can find all wallpapers [here](https://github.com/ilyamiro/shell-wallpapers).

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues.
