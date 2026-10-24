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

-- Companion Quickshell config (bar, lock, widgets)
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c onyx")
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

-- Binds
if lockVerified then
    hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -c onyx ipc call lock lock"))
end
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("qs -c onyx ipc call bar toggle"))

-- Layer rules (Caelestia's own caelestia-* rules stay as the dots define them)
hl.layer_rule({ match = { namespace = "onyx-hotzone" }, no_anim = true })
hl.layer_rule({ match = { namespace = "onyx-widgets" }, no_anim = true })
hl.layer_rule({ match = { namespace = "onyx-bar" },     no_anim = true })
