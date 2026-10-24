-- User Hyprland config for the Caelestia dots (~/.config/caelestia/hypr-user.lua).
-- Obsidian desk (2026-10-24): cosmetics live in hypr-obsidian.lua + hypr-vars.lua;
-- this file keeps the machine-specific, functional pieces.

local home = os.getenv("HOME")
local cfg  = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- GPU mode (toggled from the dashboard Customise tab, applied at login).
-- "igpu": Hyprland only opens the Intel iGPU so the NVIDIA dGPU can sleep (RTD3).
--         Outputs wired to the dGPU (HDMI-A-5, DP-3) won't work in this mode.
-- "hybrid" / missing: Hyprland's default (both GPUs).
do
    local state = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/caelestia/gpu-mode"
    local f = io.open(state, "r")
    local mode = f and f:read("*l") or "hybrid"
    if f then f:close() end
    if mode == "igpu" then
        local p = io.popen("readlink -f /dev/dri/by-path/pci-0000:00:02.0-card")
        local card = p and p:read("*l") or ""
        if p then p:close() end
        if card:match("^/dev/dri/card%d+$") then
            hl.env("AQ_DRM_DEVICES", card)
        end
    end
end

-- Lock as soon as the session starts (paired with SDDM autologin, so login/logout
-- lands on the lock screen). The companion lock takes over once enable-lock.sh has
-- recorded a passed §7 test; before that Caelestia's lock is used.
hl.on("hyprland.start", function()
    if exists(cfg .. "/onyx/.lock-verified") then
        hl.exec_cmd("for i in $(seq 100); do qs -c onyx ipc call lock isLocked >/dev/null 2>&1 && break; sleep 0.1; done; qs -c onyx ipc call lock lock")
    else
        hl.exec_cmd("for i in $(seq 50); do caelestia shell lock isLocked >/dev/null 2>&1 && break; sleep 0.1; done; caelestia shell lock lock")
    end
end)

-- Bluetooth pairing agent (Caelestia has none, so incoming pairing e.g. Echo Dot gets rejected)
hl.on("hyprland.start", function()
    hl.exec_cmd("blueman-applet")
end)

-- Obsidian (vault: ~/Projects/Obsidian/Abdullah's Vault)
hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"))

-- Laptop panel pinned to 144 Hz at all times (never auto-switch on battery)
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "auto", scale = 1 })


-- Obsidian desk: companion shell, binds, animations, layer rules
require("hypr-obsidian")
