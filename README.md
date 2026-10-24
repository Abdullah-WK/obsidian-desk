# Obsidian desk

A near-black, zero-chroma desktop for Arch + Hyprland + Caelestia. Caelestia stays installed
and unmodified (configured through `shell.json` and a custom colour scheme); a companion
Quickshell config (`qs -c onyx`) adds the hidden top status bar with hover popouts, the
full-screen lock with hover glyphs, and the desktop widget column. Thunar is restyled through
a Caelestia user template. The only chromatic colour is "Arch ice" `#8fb8d8`.

Built from `OBSIDIAN_SPEC.md` (design page: https://claude.ai/artifact/3i4123QPPfKacBYBU9gkjC).

## Layout

```
install.sh / uninstall.sh / enable-lock.sh / lib.sh
caelestia/shell.json  caelestia/cli.json          # merged into ~/.config/caelestia (your extra keys are kept)
caelestia/templates/gtk.css                        # rendered by the CLI → ~/.local/state/caelestia/theme/gtk.css
caelestia/hooks/post-scheme.sh                     # cli.json postHook: regenerates the Graphite icons, Papirus grey folders, dconf gtk/icon theme
icons/graphite-generate.py                         # → ~/.local/share/icons/Graphite (monochrome line icons from the live scheme, rest from Papirus-Dark)
scheme/dark.txt                                    # → <scheme_data_dir>/onyx/obsidian/dark.txt  (needs sudo)
quickshell/onyx/                                   # → ~/.config/quickshell/onyx   (bar/, lock/, widgets/, services/)
onyx/config.json                                   # → ~/.config/onyx/config.json  (user settings, see below)
hypr/obsidian.lua  hypr/hypr-vars.lua  hypr/hypr-user.lua   # → ~/.config/caelestia/ (Lua dots); hypr/obsidian.conf for classic configs
thunar/apply.sh                                    # xfconf: details view, hidden menubar (Ctrl+M), location entry, thumbnails (tumbler)
terminal/                                          # fish user-config (fzf keys, bat, h <cmd>), scheme templates for fzf/starship, foot tweaks
```

## Install

```sh
./install.sh
```

Idempotent. Everything it replaces is backed up under
`~/.local/state/caelestia/backups/obsidian-<date>/`. Root-only steps are printed at the end
(`pacman -S inter-font`, the scheme copy into the CLI's data dir, `papirus-folders -C grey`);
run them, then re-run `./install.sh` to finish (`caelestia scheme set -n onyx -f obsidian -m dark`).

Re-run `./install.sh` after a `caelestia-cli` update: the scheme lives inside the package's
data directory and is lost on upgrade.

## Lock (read before binding it)

The companion lock is a `WlSessionLock` + PAM; a lock that cannot unlock is a hard lockout.
`install.sh` leaves Super+L, the idle timeout and the login lock on Caelestia's lock and ships
the companion lock with a 30 s debug auto-unlock (`lockDebugAutoUnlockSec` in
`~/.config/onyx/config.json`).

1. Open a second TTY (Ctrl+Alt+F3) and log in, so a stuck lock can be killed with `pkill -f "qs -c onyx"`.
2. `qs -c onyx ipc call lock lock` → type a wrong password (shake) → the right one (unlock).
   Repeat three times, on every monitor. (`qs -p ~/.config/quickshell/onyx/LockHarness.qml`
   shows the same surface in a plain window with real PAM for visual checks.)
3. `./enable-lock.sh` → auto-unlock off, idle action → companion lock, Super+L → companion lock
   (Caelestia's lock moves to Super+Ctrl+L; Super+Alt+L stays the dots' restore-lock), login lock → companion lock. `./enable-lock.sh --undo` reverts.

## Daily use

| | |
|---|---|
| Top bar | permanent by default (`barPinned`, reserves its 36 px); with `barPinned: false` it hides above the edge and the top edge reveals it; hover an item for its popout |
| Pin the bar | Super+Shift+B or `qs -c onyx ipc call bar pin\|unpin\|toggle`; Esc unpins; Tab/Enter work while pinned |
| Lock | `qs -c onyx ipc call lock lock`; global shortcut `onyx:lock` |
| Wallpaper picker | Super+Shift+W or `qs -c onyx ipc call wallpaper toggle`: strip of sheared thumbnails; arrows/hjkl, Tab wraps, u/d page, Enter or click selects (`caelestia wallpaper -f`), Esc closes. `wallpaper.{dir,shown,height,shear,keepOpen}` in the config |
| Restart everything | `desk-restart` (Hyprland reload + both shells; refuses while locked). No watchdog: if a shell dies, run this. |
| Caelestia | dashboard/launcher/sidebar on their keybinds; its own bar (`bar.excludedScreens`) , the right-edge OSD (`osd.enabled: false`) and the sidebar hover (`sidebar.showOnHover: false`) are off, the tray lives in the top bar |
| Settings | `~/.config/onyx/config.json` (watched): `reducedMotion`, `barPinned`, `updatesIntervalMin`, `updatesOnBattery`, `wallpaper.*`, `widgetsEnabled`, `widgets.*`, `perfCommand`, `updatesCommand`, `logoutCommand`, `trayHidden`, `lock.{hideNotifs,use24h,showWeather,showMedia,dotField}` |

Colours follow `~/.local/state/caelestia/scheme.json`, so `caelestia scheme set …` recolours the
bar, lock, widgets, GTK, foot, btop and Hyprland together.

## Revert

```sh
./uninstall.sh            # restores the latest obsidian-* backup
./uninstall.sh <backup>   # or a specific one
```

## Notes

- Also applied on this machine: `~/.config/foot/foot.ini` alpha 1.0 (dots-owned file, `caelestia update` may reset it).

- Widgets sit on the `bottom` layer (not `background`) so Caelestia's wallpaper layer cannot
  cover them when the shell restarts. They are click-through except the updates card.
- Game mode (Caelestia) hides the bar, hot zone and widgets; the state is read on start, on
  `configreloaded` and on each hot-zone contact (no polling).
- Colour roles are exposed as `Scheme.fgSurface` etc. instead of `onSurface`: a QML property
  that starts with `on` + capital letter is parsed as a signal handler.
