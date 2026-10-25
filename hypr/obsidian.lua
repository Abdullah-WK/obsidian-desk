-- Obsidian desk: Hyprland (Lua) additions for the Caelestia dots.
-- Installed as ~/.config/caelestia/hypr-obsidian.lua and required from hypr-user.lua.
-- Gaps, rounding, borders, blur and shadow are set through hypr-vars.lua (the dots'
-- variables table); this file holds the companion shell, binds, animations, layer rules.

local home = os.getenv("HOME")
local cfg  = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Written by enable-lock.sh once the §7 lock test has passed. Until then Super+L and
-- the login lock stay on Caelestia's own lock.
local lockVerified = exists(cfg .. "/onyx/.lock-verified")

-- Companion Quickshell config (bar, lock, widgets). Once the lock is verified it starts
-- locked, so the lock screen is the first thing on screen at every login.
hl.on("hyprland.start", function()
    if lockVerified then
        hl.exec_cmd("env ONYX_LOCK_ON_START=1 qs -c onyx")
    else
        hl.exec_cmd("qs -c onyx")
    end
end)

-- Display gamma: a slightly steeper curve so blacks and dark greys sit deeper ("OLED" feel).
-- Temperatures 6499/6500 (wlsunset insists high > low) → no visible colour shift. Tune live with:
--   pkill wlsunset; setsid -f wlsunset -t 6499 -T 6500 -g 0.85
local displayGamma = 0.85
hl.on("hyprland.start", function()
    hl.exec_cmd("wlsunset -t 6499 -T 6500 -g " .. displayGamma)
end)

-- Motion: standard / decel curves, 200–250 ms (matches the shell's 0.7 duration scale)
hl.curve("obsidianStd",   { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("obsidianDecel", { type = "bezier", points = { { 0, 0 }, { 0, 1 } } })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2,   bezier = "obsidianDecel", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2,   bezier = "obsidianStd",   style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2,   bezier = "obsidianDecel" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2,   bezier = "obsidianStd" })
hl.animation({ leaf = "fadeDim",     enabled = true, speed = 2,   bezier = "obsidianStd" })
hl.animation({ leaf = "fadeLayers",  enabled = true, speed = 2,   bezier = "obsidianStd" })
hl.animation({ leaf = "border",      enabled = true, speed = 2,   bezier = "obsidianStd" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 2.5, bezier = "obsidianDecel", style = "slide" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 2,   bezier = "obsidianDecel", style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 2,   bezier = "obsidianStd",   style = "fade" })

-- Unfocused windows recede slightly (redraws only on focus change)
hl.config({ decoration = { dim_inactive = true, dim_strength = 0.08 } })

-- Diagnostics (2026-10-26, after an unexplained "Hyprland died"): keep Hyprland's own log on
-- (default off) and mirror it + SDDM's session log to ~/.local/state/hyprland/ (last 6 sessions),
-- since both originals vanish at logout. `hyprland-current.log` / `session-current.log` point at
-- this session. Costs a few MB per session; drop this block once things are stable.
hl.config({ debug = { disable_logs = false } })
hl.on("hyprland.start", function()
    hl.exec_cmd(home .. "/.local/bin/hypr-logmirror")
end)


-- Binds
if lockVerified then
    hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -c onyx ipc call lock lock"))
end
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("qs -c onyx ipc call bar toggle"))
-- Super+W is the dots' browser bind, so the picker takes Super+Shift+W
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("qs -c onyx ipc call wallpaper toggle"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("qs -c onyx ipc call session toggle"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("qs -c onyx ipc call session toggle"))
-- a tap of Super opens the onyx launcher (the dots' launcher bind moved to Super+Ctrl+Space in hypr-vars)
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("qs -c onyx ipc call launcher toggle"), { release = true })

-- Layer rules (Caelestia's own caelestia-* rules stay as the dots define them)
hl.layer_rule({ match = { namespace = "onyx-hotzone" }, no_anim = true })
hl.layer_rule({ match = { namespace = "onyx-widgets" }, no_anim = true })
hl.layer_rule({ match = { namespace = "onyx-bar" },     no_anim = true })
hl.layer_rule({ match = { namespace = "onyx-(session|wallpaper|launcher)" }, no_anim = true })
