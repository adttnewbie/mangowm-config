# Package Management

This document describes the package requirements for the Arch Linux + MangoWM
desktop configuration.

## Package Lists

- `packages-pacman.txt` — Official Arch repository packages
- `packages-aur.txt` — AUR (Arch User Repository) packages

## Installation

### Prerequisites

An AUR helper is required to install AUR packages. Common choices:

- `yay` — Yet Another Yogurt
- `paru` — Feature-packed AUR helper

The installation scripts detect and use whichever AUR helper is available.

### Package Groups

#### Core

Essential packages for the MangoWM session:

- `mango` or `mangowm-git` — The MangoWM compositor
- `quickshell` or `quickshell-git` — QML-based shell for panels and widgets
- `swayidle`, `swaylock` — Idle management and screen locking
- `swww` — Wallpaper daemon
- `wl-clipboard`, `cliphist` — Clipboard management

#### Terminal and Shell

- `kitty` — GPU-accelerated terminal emulator
- `zsh` with completions, autosuggestions, syntax-highlighting

#### Application Launcher

- `rofi` — Application launcher and window switcher

#### Audio

- `pipewire`, `pipewire-pulse`, `wireplumber` — Audio server and session manager
- `pavucontrol` — PulseAudio volume control GUI
- `playerctl` — Media player control

#### Screenshot and Recording

- `grim`, `slurp` — Screenshot tools
- `swappy`, `satty` — Screenshot annotation

#### Theming

- `adw-gtk-theme`, `adwaita-icon-theme` — GNOME/Adwaita theming
- `qt6ct` — Qt6 configuration tool
- `whitesur-cursor-theme-git` (AUR) — Cursor theme

#### Fonts

- `ttf-jetbrains-mono` — Monospace font
- `ttf-font-awesome` — Icon font
- `noto-fonts`, `noto-fonts-cjk`, `noto-fonts-emoji` — Comprehensive font coverage

#### Color Generation

- `matugen` — Material You color generation from wallpapers

### Optional Dependencies

These packages enhance the desktop experience but are not required:

- `cava` — Audio visualizer
- `lavat` — Lava lamp animation
- `cbonsai` — Bonsai tree generator
- `btop` — Resource monitor
- `fastfetch` — System information display

## AUR Helper Behavior

The installation scripts (`install/packages.sh`) will:

1. Detect available AUR helpers (`yay`, `paru`)
2. Install official packages with `pacman`
3. Install AUR packages with the detected helper
4. Skip packages that are already installed
5. Report any installation failures

## Updating Packages

```bash
# Official packages
sudo pacman -Syu

# AUR packages (with yay)
yay -Syu

# Or use the installation script
./install/packages.sh
```
