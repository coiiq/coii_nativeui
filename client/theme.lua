local hex = type(Config.AccentColour) == 'string' and Config.AccentColour:match('^#?(%x%x%x%x%x%x)$')
if not hex then
    print('[coii_nativeui] Invalid AccentColour; use a six-digit hex colour such as #50B7F5.')
    hex = '50B7F5'
end
local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
CoiiTheme = { hex = '#' .. hex:upper(), r = r, g = g, b = b }
local background = type(Config.BackgroundColour) == 'string' and Config.BackgroundColour:match('^#?(%x%x%x%x%x%x)$')
if not background then
    print('[coii_nativeui] Invalid BackgroundColour; using #0B1320.')
    background = '0B1320'
end
CoiiTheme.background = {
    hex = '#' .. background:upper(),
    r = tonumber(background:sub(1, 2), 16),
    g = tonumber(background:sub(3, 4), 16),
    b = tonumber(background:sub(5, 6), 16)
}
local function scaled(red, green, blue, alpha)
    return { r = math.floor(r * red + .5), g = math.floor(g * green + .5), b = math.floor(b * blue + .5), a = alpha }
end
CoiiTheme.backdrop = Config.PauseBackdrop.useAccent == false and Config.PauseBackdrop.colour
    or scaled(0, 74/183, 125/245, Config.PauseBackdrop.colour.a)
if Config.PauseBackdrop.useBackground == true then
    CoiiTheme.backdrop = { r = CoiiTheme.background.r, g = CoiiTheme.background.g,
        b = CoiiTheme.background.b, a = Config.PauseBackdrop.colour.a }
end
CoiiTheme.waypoint = Config.WaypointColour.useAccent == false and Config.WaypointColour
    or scaled(60/80, 140/183, 200/245, Config.WaypointColour.a)
