#!/usr/bin/env bash
# Link the rendered Obsidian userChrome.css into every Firefox profile and enable legacy
# stylesheet customisations. Firefox must be restarted afterwards. Idempotent.
CSS=${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/theme/firefox-userChrome.css
for ini in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox/profiles.ini" "$HOME/.mozilla/firefox/profiles.ini"; do
    [ -f "$ini" ] || continue
    base=$(dirname "$ini")
    grep -E '^Path=' "$ini" | cut -d= -f2 | while read -r rel; do
        P="$base/$rel"; [ -d "$P" ] || continue
        mkdir -p "$P/chrome"
        ln -sfn "$CSS" "$P/chrome/userChrome.css"
        grep -q 'legacyUserProfileCustomizations.stylesheets", true' "$P/user.js" 2>/dev/null || echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$P/user.js"
        echo "firefox profile $rel: userChrome linked"
    done
done
