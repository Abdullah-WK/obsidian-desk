-- Obsidian desk: overrides for the Caelestia dots' hypr/variables.lua.
-- Installed as ~/.config/caelestia/hypr-vars.lua (read by hyprland.lua before the dots' modules).
local scheme = require("scheme.current")

local home = os.getenv("HOME")
local cfg  = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local f = io.open(cfg .. "/onyx/.lock-verified", "r")
local lockVerified = f ~= nil
if f then f:close() end

return {
    cursorTheme                = "Bibata-Modern-Ice",

    -- Opaque windows, no blur, no shadow (largest GPU saving)
    windowOpacity              = 1.0,
    blurEnabled                = false,
    shadowEnabled              = false,

    -- Geometry: gaps 6 / 10, rounding 10, 1 px border
    windowGapsIn               = 6,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 10,
    windowRounding             = 10,
    windowRoundingPower        = 2,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgba(" .. scheme.outlineVariant .. "ff)",
    inactiveWindowBorderColour = "rgba(" .. scheme.surfaceContainerHigh .. "ff)",

    -- Caelestia's own lock keeps a key, but moves off Super+L once the companion lock owns it
    kbLock                     = lockVerified and "SUPER + CTRL + L" or "SUPER + L",
}
