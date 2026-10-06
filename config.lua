Config = {}
-- Debug messages.
Config.Debug = false

-- Server name and logo.
Config.ServerName = 'NORTHGARD ROLEPLAY'
Config.ServerLogo = 'web/logo.png'

-- Hex colours. Restart after changing.
Config.AccentColour = '#50B7F5'
Config.BackgroundColour = '#0B1320'

-- Set false to disable the gameplay minimap. Map and menus stay enabled.
Config.MinimapEnabled = true

-- Update intervals in milliseconds.
Config.UpdateInterval = 200
Config.EnvironmentPollInterval = 500

Config.ShowOnFoot = true
Config.HideWhenDead = true
Config.HideInPauseMenu = true
-- Call your HUD export here: false hides it, true restores it. No Wait/loops.
Config.SetHudVisible = function(visible)
    -- exports['your_hud']:SetVisible(visible)
end

-- Pause menu.
Config.QuickMenu = {
    enabled = true,
    title = 'San Andreas',
    -- HTTPS website. Empty disables the button.
    website = '',
    blur = true,
    returnFromNative = true,
    mapFrontend = 'FE_MENU_VERSION_SP_PAUSE',
    settingsFrontend = 'FE_MENU_VERSION_LANDING_MENU'
}
-- Use GPS route distance instead of straight-line distance.
Config.UseGpsRouteLength = true

-- Background behind native menus.
Config.PauseBackdrop = {
    enabled = true,
    scanlines = true,
    useBackground = true, -- Use BackgroundColour.
    useAccent = true, -- Use AccentColour when useBackground is false.
    colour = { r = 0, g = 74, b = 125, a = 105 }
}

-- Waypoint route colour.
Config.ReplaceWaypointColour = true
Config.WaypointColour = { r = 60, g = 140, b = 200, a = 255, useAccent = true }

-- Minimap position and size.
Config.Ui = {
    leftVw = 2.2,
    bottomVh = 3.2,
    scale = 1.0
}

-- Native radar settings.
Config.NativeMinimap = {
    maskFile = 'assets/radar-mask.png',
    centerPlayer = true, -- Keep the player centred.
    hideNativeNorth = true,
    hideNativeSatnav = true,
    hideHealthArmor = true,
    scaleformTimeoutMs = 5000,

    -- Default radar layout restored on resource stop.
    restoreComponents = {
        minimap = { -0.0045, 0.002, 0.150, 0.188888 },
        minimap_mask = { 0.020, 0.032, 0.111, 0.159 },
        minimap_blur = { -0.030, 0.022, 0.266, 0.237 }
    }
}
