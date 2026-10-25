#!/usr/bin/env bash
# dev helper: copy the repo's companion config over the installed one and relaunch it
HERE=$(cd "$(dirname "$0")/.." && pwd)
rsync -a --delete --exclude '_*' "$HERE/quickshell/onyx/" "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/onyx/"
exec "$HERE/dev/relaunch.sh" "$@"
