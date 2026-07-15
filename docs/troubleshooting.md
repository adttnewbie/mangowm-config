# Troubleshooting

## Installation Issues

### AUR helper not found

The installer requires an AUR helper (yay or paru). Install one first:

```bash
# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

### Package installation fails

Ensure your system is up to date:

```bash
sudo pacman -Syu
```

Then re-run the installer.

## Session Issues

### MangoWM doesn't start

Check that Mango is installed:

```bash
which mango
mango -v
```

If not installed, install from AUR:

```bash
yay -S mangowm-git
```

### QuickShell doesn't start

Check QuickShell installation:

```bash
which quickshell
quickshell --version
```

If not installed:

```bash
yay -S quickshell-git
```

### Black screen after login

1. Switch to TTY (Ctrl+Alt+F2)
2. Check logs: `journalctl --user -u graphical-session`
3. Try starting Mango manually: `mango`

## Configuration Issues

### Monitor not detected

Edit `~/.config/mango/conf.d/monitors.conf` and add your monitor:

```
monitorrule=name:^DP-1$,width:2560,height:1440,refresh:165,x:0,y:0,scale:1
```

Use `wlr-randr` or `wayland-info` to find your monitor name.

### Keyboard layout not switching

Ensure your layout is configured in `~/.config/mango/conf.d/input.conf`:

```
xkb_rules_layout=us,ru
xkb_rules_options=grp:alt_shift_toggle
```

### Colors not updating

Run Matugen with a wallpaper:

```bash
matugen image /path/to/wallpaper.png
```

## Performance Issues

### High CPU usage

Check for runaway processes:

```bash
btop
```

Common causes:
- Wallpaper animation (swww) — try a static image
- QuickShell widgets — disable unused popups

### Screen tearing

MangoWM should not have tearing. If you see it:
1. Check your GPU driver
2. For NVIDIA, ensure the proprietary driver is installed
3. Try disabling VRR in monitor settings

## Getting Help

- Check [MIGRATION.md](../MIGRATION.md) for known behavior changes
- Open an issue on GitHub
