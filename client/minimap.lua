local RESOURCE_NAME = GetCurrentResourceName()
local TEXTURE_DICTIONARY = RESOURCE_NAME .. '_radar'
local WAYPOINT_BLIP_SPRITE = 8
local WAYPOINT_HUD_COLOUR = 142
local ESX = exports['es_extended']:getSharedObject()
local minimapEnabled = Config.MinimapEnabled ~= false

local nuiReady = false
local visibilityOverride = nil
local playerLoaded = ESX.IsPlayerLoaded() == true
local layout = nil
local layoutDirty = false
local prepared = false
local preparing = false
local failed = false
local stopped = false
local texturesInstalled = false
local scaleform = nil
local lastEnvironment = nil
local lastPayload = nil
local originalRadarVisible = not IsRadarHidden()
local originalNorthAlpha = nil
local originalWaypointColour = nil
local appliedWaypointColour = nil

local function finite(value)
    return type(value) == 'number'
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function healthArmorMode(mode)
    if not scaleform or not HasScaleformMovieLoaded(scaleform) then return end

    BeginScaleformMovieMethod(scaleform, 'SETUP_HEALTH_ARMOUR')
    ScaleformMovieMethodAddParamInt(mode)
    EndScaleformMovieMethod()
end

local function satnavVisible(visible)
    if not scaleform or not HasScaleformMovieLoaded(scaleform) then return end

    BeginScaleformMovieMethod(scaleform, visible and 'SHOW_SATNAV' or 'HIDE_SATNAV')
    EndScaleformMovieMethod()
end

local function centerMinimapOnPlayer()
    if not Config.NativeMinimap.centerPlayer then return end

    UnlockMinimapPosition()
    CenterPlayerOnRadarThisFrame()
end

local function applyWaypointColour()
    if not Config.ReplaceWaypointColour then return end

    if not originalWaypointColour then
        originalWaypointColour = { GetHudColour(WAYPOINT_HUD_COLOUR) }
    end

    local colour = CoiiTheme.waypoint
    ReplaceHudColourWithRgba(WAYPOINT_HUD_COLOUR, colour.r, colour.g, colour.b, colour.a)
    appliedWaypointColour = { colour.r, colour.g, colour.b, colour.a }
end

local function prepareNativeRadar()
    if prepared or preparing or failed or not minimapEnabled then return prepared end

    preparing = true

    local ok, texture = pcall(function()
        local dictionary = CreateRuntimeTxd(TEXTURE_DICTIONARY)
        return CreateRuntimeTextureFromImage(dictionary, 'mask', Config.NativeMinimap.maskFile)
    end)

    if not ok or not texture or texture == 0 then
        failed = true
        preparing = false
        print(('^1[%s] Could not load %s. The original GTA radar was left untouched.^7'):format(RESOURCE_NAME, Config.NativeMinimap.maskFile))
        return false
    end

    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', TEXTURE_DICTIONARY, 'mask')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', TEXTURE_DICTIONARY, 'mask')
    texturesInstalled = true

    UnlockMinimapPosition()

    SetMinimapClipType(1)

    if Config.NativeMinimap.hideNativeNorth then
        local northBlip = GetNorthRadarBlip()

        if northBlip and northBlip ~= 0 then
            originalNorthAlpha = GetBlipAlpha(northBlip)
            SetBlipAlpha(northBlip, 0)
        end
    end

    if Config.NativeMinimap.hideHealthArmor or Config.NativeMinimap.hideNativeSatnav then
        scaleform = RequestScaleformMovie('minimap')
        local deadline = GetGameTimer() + Config.NativeMinimap.scaleformTimeoutMs

        while not HasScaleformMovieLoaded(scaleform) and GetGameTimer() < deadline do
            Wait(25)
            if stopped then
                preparing = false
                return false
            end
        end

        if not HasScaleformMovieLoaded(scaleform) then
            print(('^3[%s] Minimap scaleform timed out; native satnav or health/armor bars may remain visible.^7'):format(RESOURCE_NAME))
        end
    end

    applyWaypointColour()

    SetMinimapBlockWaypoint(false)
    if IsWaypointActive() then RefreshWaypoint() end

    prepared = true
    preparing = false
    layoutDirty = true
    return true
end

local function currentEnvironment()
    local width, height = GetActiveScreenResolution()
    return ('%s:%s:%.4f:%.4f'):format(width, height, GetSafeZoneSize(), GetAspectRatio(false))
end

local function applyMeasuredLayout()
    if not prepared or not layout or IsPauseMenuActive() or IsBigmapActive() then return end

    SetScriptGfxAlign(string.byte('L'), string.byte('B'))
    local originX, originY = GetScriptGfxPosition(0.0, 0.0)
    local extentX, extentY = GetScriptGfxPosition(1.0, 1.0)
    ResetScriptGfxAlign()

    local scaleX = extentX - originX
    local scaleY = extentY - originY

    if not finite(scaleX) or not finite(scaleY) or scaleX < 0.0001 or scaleY < 0.0001 then
        return
    end

    local x = (layout.left - originX) / scaleX
    local y = (layout.top + layout.height - originY) / scaleY
    local width = layout.width / scaleX
    local height = layout.height / scaleY

    SetMinimapComponentPosition('minimap', 'L', 'B', x, y, width, height)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', x, y, width, height)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', x, y, width, height)
    layoutDirty = false

    SetBigmapActive(true, false)
    Wait(0)
    SetBigmapActive(false, false)
    SetMinimapClipType(1)
end

function RefreshMinimapLayout()
    if not minimapEnabled then return end
    layoutDirty = true
end

function SetMinimapVisible(state)
    if not minimapEnabled then return end
    if state == nil then
        visibilityOverride = nil
        return
    end

    visibilityOverride = state == true

    if not visibilityOverride then
        DisplayRadar(false)
        SendNUIMessage({ action = 'coii:minimap:update', visible = false })
        lastPayload = nil
    end
end

local function sendConfiguration()
    SendNUIMessage({
        action = 'coii:minimap:configure',
        accent = CoiiTheme.hex,
        background = CoiiTheme.background.hex,
        ui = Config.Ui
    })
end

local function resolveTextLabel(label)
    if not label or label == '' then return '' end

    local resolved = GetLabelText(label)
    if not resolved or resolved == '' or resolved == 'NULL' then return label end
    return resolved
end

local function getLocation(coords)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = ''

    if streetHash and streetHash ~= 0 then
        street = GetStreetNameFromHashKey(streetHash)
    end

    local district = resolveTextLabel(GetNameOfZone(coords.x, coords.y, coords.z))
    return district ~= '' and district or 'San Andreas', street ~= '' and street or district
end

local function getWaypointDistance(coords)
    local waypoint = GetFirstBlipInfoId(WAYPOINT_BLIP_SPRITE)
    if waypoint == 0 or not DoesBlipExist(waypoint) then return 0 end

    local destination = GetBlipInfoIdCoord(waypoint)
    local deltaX = coords.x - destination.x
    local deltaY = coords.y - destination.y
    local directDistance = math.sqrt((deltaX * deltaX) + (deltaY * deltaY))

    if Config.UseGpsRouteLength and type(GetGpsBlipRouteLength) == 'function' then
        local ok, routeDistance = pcall(GetGpsBlipRouteLength)
        if ok and finite(routeDistance) and routeDistance > 0 then return routeDistance end
    end

    return directDistance
end

local function wantsRadar(ped)
    if not playerLoaded then return false end
    if CoiiQuickMenuIsOpen and CoiiQuickMenuIsOpen() then return false end
    if Config.HideInPauseMenu and (IsPauseMenuActive() or IsBigmapActive()) then return false end
    if Config.HideWhenDead and IsEntityDead(ped) then return false end
    if IsScreenFadedOut() then return false end
    if visibilityOverride ~= nil then return visibilityOverride end
    if not Config.ShowOnFoot and not IsPedInAnyVehicle(ped, false) then return false end
    return true
end

local pauseLinesReady = false
local pauseLinesDictionary = RESOURCE_NAME .. '_pause_lines'
local function drawPauseBackdrop()
    local backdrop = Config.PauseBackdrop
    if not backdrop or not backdrop.enabled or not playerLoaded then return end
    if not IsPauseMenuActive() or GetIsLoadingScreenActive() or IsScreenFadedOut() then return end

    local colour = CoiiTheme.backdrop
    SetScriptGfxDrawBehindPausemenu(true)
    SetScriptGfxDrawOrder(0)
    DrawRect(0.5, 0.5, 1.0, 1.0, colour.r, colour.g, colour.b, colour.a)
    if backdrop.scanlines ~= false then
        if not pauseLinesReady then
            local dictionary = CreateRuntimeTxd(pauseLinesDictionary)
            CreateRuntimeTextureFromImage(dictionary, 'lines', 'assets/pause-lines.png')
            pauseLinesReady = true
        end
        DrawSprite(pauseLinesDictionary, 'lines', 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    end
    SetScriptGfxDrawOrder(1)
    SetScriptGfxDrawBehindPausemenu(false)
end

local function payloadChanged(payload)
    if not lastPayload then return true end

    return payload.visible ~= lastPayload.visible
        or payload.heading ~= lastPayload.heading
        or payload.distance ~= lastPayload.distance
        or payload.district ~= lastPayload.district
        or payload.street ~= lastPayload.street
        or payload.lighting ~= lastPayload.lighting
end

RegisterNUICallback('ready', function(_, callback)
    nuiReady = true
    sendConfiguration()
    callback({ ok = true })
end)

RegisterNUICallback('layout', function(data, callback)
    if not minimapEnabled then
        callback({ ok = true, disabled = true })
        return
    end
    local valid = type(data) == 'table'
        and finite(data.left) and finite(data.top)
        and finite(data.width) and finite(data.height)
        and data.left >= 0 and data.top >= 0
        and data.width > 0.01 and data.height > 0.01
        and data.left + data.width <= 1.001
        and data.top + data.height <= 1.001

    if not valid then
        callback({ ok = false, error = 'invalid_layout' })
        return
    end

    layout = {
        left = data.left,
        top = data.top,
        width = data.width,
        height = data.height
    }
    layoutDirty = true
    callback({ ok = true })
end)

RegisterNetEvent('esx:playerLoaded', function()
    playerLoaded = true
    layoutDirty = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    playerLoaded = false
    lastPayload = nil
    if minimapEnabled then DisplayRadar(false) end
end)

CreateThread(function()
    while not stopped do
        local frameworkLoaded = ESX.IsPlayerLoaded() == true
        if frameworkLoaded ~= playerLoaded then
            playerLoaded = frameworkLoaded
            if playerLoaded then layoutDirty = true end
        end

        if playerLoaded and IsPauseMenuActive() and BeginScaleformMovieMethodOnFrontend('COII_SET_ACCENT') then
            ScaleformMovieMethodAddParamInt(CoiiTheme.r)
            ScaleformMovieMethodAddParamInt(CoiiTheme.g)
            ScaleformMovieMethodAddParamInt(CoiiTheme.b)
            EndScaleformMovieMethod()
        end

        if playerLoaded and IsPauseMenuActive() then
            for _, method in ipairs({ 'COII_SET_BACKGROUND', 'COII_SET_KEYMAP_BACKGROUND' }) do
                if BeginScaleformMovieMethodOnFrontend(method) then
                    ScaleformMovieMethodAddParamInt(CoiiTheme.background.r)
                    ScaleformMovieMethodAddParamInt(CoiiTheme.background.g)
                    ScaleformMovieMethodAddParamInt(CoiiTheme.background.b)
                    EndScaleformMovieMethod()
                end
            end
        end

        if minimapEnabled and playerLoaded and nuiReady and layout and not prepared and not failed then
            prepareNativeRadar()
        end

        if prepared then
            local environment = currentEnvironment()
            if environment ~= lastEnvironment then
                lastEnvironment = environment
                layoutDirty = true
            end

            if layoutDirty then applyMeasuredLayout() end
        end

        Wait(Config.EnvironmentPollInterval)
    end
end)

CreateThread(function()
    while not stopped do
        local ped = PlayerPedId()
        local visible = prepared and wantsRadar(ped)
        if minimapEnabled then DisplayRadar(visible) end
        drawPauseBackdrop()

        if visible then
            SetMinimapClipType(1)
            centerMinimapOnPlayer()

            if Config.NativeMinimap.hideNativeSatnav then
                satnavVisible(false)
            end

            if Config.NativeMinimap.hideHealthArmor then
                healthArmorMode(3)
            end
        end

        if prepared or IsPauseMenuActive() then
            Wait(0)
        else
            Wait(100)
        end
    end
end)

CreateThread(function()
    while not stopped do
        local ped = PlayerPedId()
        local visible = prepared and wantsRadar(ped)
        local payload = {
            action = 'coii:minimap:update',
            visible = visible,
            heading = 0,
            distance = 0,
            district = '',
            street = '',
            lighting = 'day'
        }

        if visible then
            local coords = GetEntityCoords(ped)
            local district, street = getLocation(coords)
            local hour = GetClockHours()

            payload.heading = math.floor((GetEntityHeading(ped) + 0.5) % 360)
            payload.distance = math.floor(getWaypointDistance(coords) + 0.5)
            payload.district = district
            payload.street = street
            payload.lighting = (hour >= 20 or hour < 6) and 'night' or 'day'
        end

        if nuiReady and payloadChanged(payload) then
            SendNUIMessage(payload)
            lastPayload = payload
        end

        Wait(Config.UpdateInterval)
    end
end)

local function sameColour(left, right)
    if not left or not right then return false end
    for index = 1, 4 do
        if left[index] ~= right[index] then return false end
    end
    return true
end

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= RESOURCE_NAME then return end
    stopped = true

    if not minimapEnabled then return end

    if texturesInstalled then
        RemoveReplaceTexture('platform:/textures/graphics', 'radarmasksm')
        RemoveReplaceTexture('platform:/textures/graphics', 'radarmask1g')
    end

    UnlockMinimapPosition()
    SetMinimapBlockWaypoint(false)
    if IsWaypointActive() then RefreshWaypoint() end

    if prepared then
        for name, values in pairs(Config.NativeMinimap.restoreComponents) do
            SetMinimapComponentPosition(name, 'L', 'B', values[1], values[2], values[3], values[4])
        end

        SetMinimapClipType(0)

        if Config.NativeMinimap.hideNativeSatnav then
            satnavVisible(true)
        end

        healthArmorMode(0)
        local northBlip = GetNorthRadarBlip()
        if northBlip and northBlip ~= 0 and originalNorthAlpha then
            SetBlipAlpha(northBlip, originalNorthAlpha)
        end
    end

    DisplayRadar(originalRadarVisible ~= false)

    if originalWaypointColour and appliedWaypointColour then
        local current = { GetHudColour(WAYPOINT_HUD_COLOUR) }
        if sameColour(current, appliedWaypointColour) then
            ReplaceHudColourWithRgba(WAYPOINT_HUD_COLOUR, table.unpack(originalWaypointColour))
        end
    end

    if scaleform then SetScaleformMovieAsNoLongerNeeded(scaleform) end
end)
