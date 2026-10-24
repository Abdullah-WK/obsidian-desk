# Obsidian terminal (repo ~/Projects/obsidian-desk/terminal). Sourced by the Caelestia dots'
# config.fish at the end of its interactive block, so everything here overrides the defaults.

# prompt: starship config rendered from templates/starship.toml by `caelestia scheme`
set -gx STARSHIP_CONFIG ~/.local/state/caelestia/theme/starship.toml

# bat: terminal palette (follows the scheme); man pages and --help through it
set -gx BAT_THEME ansi
set -gx BAT_STYLE numbers,changes,header
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
function h --description 'coloured --help: h <command>'
    $argv --help 2>&1 | bat -plhelp
end

# fzf: Ctrl+R history · Ctrl+T files · Alt+C directories, colours from the scheme
source ~/.local/state/caelestia/theme/fzf.fish 2>/dev/null
command -q fzf && fzf --fish | source
