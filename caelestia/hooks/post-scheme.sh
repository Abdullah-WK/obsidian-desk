#!/usr/bin/env bash
# Obsidian: runs after every `caelestia scheme set` (cli.json → theme.postHook).
# theme.enableGtk is off, so the CLI no longer writes gtk.css/thunar.css or the dconf
# keys; this hook keeps the GTK side consistent instead.

# Papirus folder colour → grey. The theme lives in /usr/share/icons, so this only
# succeeds as root; install.sh prints the sudo line once, afterwards this is a no-op.
if command -v papirus-folders >/dev/null 2>&1; then
    papirus-folders -C grey --theme Papirus-Dark >/dev/null 2>&1 || true
fi

dconf write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3-dark'"
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
# Graphite: monochrome line icons generated from the live scheme (inherits Papirus-Dark for the rest)
if [ -f "$HOME/.local/share/icons/Graphite/generate.py" ]; then
    python3 -I "$HOME/.local/share/icons/Graphite/generate.py" >/dev/null 2>&1 || true
    dconf write /org/gnome/desktop/interface/icon-theme "'Graphite'"
else
    dconf write /org/gnome/desktop/interface/icon-theme "'Papirus-Dark'"
fi

# Keep the existing tmux colour template (templates/tmux-graphite.conf) live.
tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
