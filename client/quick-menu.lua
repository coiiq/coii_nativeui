local config = Config.QuickMenu or {}
local framework = exports['es_extended']:getSharedObject()
local open, ready, stopped, ownsBlur = false, false, false, false
local session, armedQuit, cooldown = 0, nil, 0
local nativePending, nativeSeen, nativeDeadline = false, false, 0
local nativeRoute, nextBranding = nil, 0
local logoDictionary = GetCurrentResourceName() .. '_brand'
local logoReady = false
local mapExpandAt = nil
local transitioning = false
local hudHidden = false
local function setHudHidden(hidden)
    if hudHidden == hidden then return end
    hudHidden = hidden
    if type(Config.SetHudVisible) ~= 'function' then return end
    local ok, err = pcall(Config.SetHudVisible, not hidden)
    if not ok then
        print(('[coii_nativeui] Config.SetHudVisible(%s) failed: %s'):format(tostring(not hidden), tostring(err)))
    end
end
local function finishTransition()
    if not transitioning then return end
    transitioning = false
    SendNUIMessage({ action = 'coii:quick:transitionEnd', session = session })
end

local function nuiLogoPath()
    local configured = Config.ServerLogo or 'web/logo.png'
    local relative = type(configured) == 'string' and configured:match('^web/([%w%._/%-]+%.png)$') or nil
    if not relative or relative:find('..', 1, true) then return 'logo.png' end
    return relative
end

local function nativeBranding()
    if not logoReady then
        local dictionary = CreateRuntimeTxd(logoDictionary)
        CreateRuntimeTextureFromImage(dictionary, 'server_logo', Config.ServerLogo or 'web/logo.png')
        logoReady = true
    end
    if BeginScaleformMovieMethodOnFrontendHeader('COII_SET_BRANDING') then
        ScaleformMovieMethodAddParamPlayerNameString(Config.ServerName or 'COII ROLEPLAY')
        ScaleformMovieMethodAddParamPlayerNameString(logoDictionary)
        ScaleformMovieMethodAddParamPlayerNameString('server_logo')
        ScaleformMovieMethodAddParamPlayerNameString(nativeRoute or '')
        EndScaleformMovieMethod()
    end
end

function CoiiQuickMenuIsOpen() return open end

local function available()
    return config.enabled == true and ready and framework.IsPlayerLoaded() == true
        and not GetIsLoadingScreenActive() and not IsScreenFadedOut()
end

local function closeMenu(handoff)
    if not open then return end
    open = false
    armedQuit = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    if ownsBlur then TriggerScreenblurFadeOut(150); ownsBlur = false end
    SendNUIMessage({ action = 'coii:quick', visible = false, session = session, handoff = handoff == true })
    cooldown = GetGameTimer() + 350
    if not handoff and not nativePending and not IsPauseMenuActive() and not IsWarningMessageActive() then setHudHidden(false) end
end

local function openMenu()
    if not available() or open or IsPauseMenuActive() or IsWarningMessageActive() or IsNuiFocused() then return false end
    open = true
    setHudHidden(true)
    session = session + 1
    armedQuit = nil
    cooldown = GetGameTimer() + 250
    local coords = GetEntityCoords(PlayerPedId())
    local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    if not zone or zone == 'NULL' then zone = 'San Andreas' end
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    if config.blur then TriggerScreenblurFadeIn(150); ownsBlur = true end
    SendNUIMessage({ action = 'coii:quick', visible = true, session = session,
        title = config.title, brand = Config.ServerName, logo = nuiLogoPath(), player = GetPlayerName(PlayerId()),
        district = zone, website = config.website or '', accent = CoiiTheme.hex,
        background = CoiiTheme.background.hex })
    return true
end

RegisterNUICallback('quickReady', function(_, cb)
    ready = true
    cb({ ok = true })
end)

RegisterNUICallback('quickAction', function(data, cb)
    if type(data) ~= 'table' or not open or data.session ~= session or not available() then
        cb({ ok = false, error = 'Menu is no longer active.' }); return
    end
    local action = data.action
    if action == 'resume' then
        closeMenu(); cb({ ok = true })
    elseif action == 'map' or action == 'settings' then
        transitioning = true
        closeMenu(true)
        nativePending, nativeSeen = true, false
        nativeRoute, nextBranding = action, 0
        mapExpandAt = action == 'map' and 0 or nil
        nativeDeadline = GetGameTimer() + 5000
        ActivateFrontendMenu(GetHashKey(action == 'settings'
            and (config.settingsFrontend or 'FE_MENU_VERSION_LANDING_MENU')
            or (config.mapFrontend or 'FE_MENU_VERSION_SP_PAUSE')), false,
            action == 'settings' and 6 or -1)
        cb({ ok = true })
    elseif action == 'website' then
        local url = config.website
        if type(url) ~= 'string' or not url:match('^https://[%w%.%-]+[:/%?#]?') or url:find('%s') then
            cb({ ok = false, error = 'The website has not been configured.' }); return
        end
        closeMenu(); cb({ ok = true, url = url })
    elseif action == 'prepareQuit' then
        armedQuit = GetGameTimer() + 15000
        cb({ ok = true })
    elseif action == 'cancelQuit' then
        armedQuit = nil; cb({ ok = true })
    elseif action == 'quit' and data.confirmed == true and armedQuit and GetGameTimer() <= armedQuit then
        closeMenu(); cb({ ok = true })
        TriggerServerEvent('coii_nativeui:disconnect')
    else
        cb({ ok = false, error = 'Action unavailable. Please try again.' })
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    nativePending = false
    finishTransition()
    closeMenu()
    setHudHidden(false)
end)

CreateThread(function()
    while not stopped do
        local now = GetGameTimer()
        if open then
            if not available() or IsPauseMenuActive() or IsWarningMessageActive() then
                closeMenu()
            else
                DisableFrontendThisFrame()
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
                DisablePlayerFiring(PlayerId(), true)
                if now > cooldown then
                    if not IsInputDisabled(2) then
                        local key = nil
                        if IsDisabledControlJustPressed(0, 172) then key = 'up' end
                        if IsDisabledControlJustPressed(0, 173) then key = 'down' end
                        if IsDisabledControlJustPressed(0, 201) then key = 'accept' end
                        if IsDisabledControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 200) then key = 'back' end
                        if key then SendNUIMessage({ action = 'coii:quick:input', key = key }) end
                    end
                end
            end
        elseif nativePending then
            if not available() then
                nativePending = false
                finishTransition()
            elseif IsWarningMessageActive() then
                nativeSeen = true
            elseif IsPauseMenuActive() then
                nativeSeen = true
                if mapExpandAt and GetPauseMenuState() == 15 then
                    if mapExpandAt == 0 then mapExpandAt = now + 250
                    elseif now >= mapExpandAt and BeginScaleformMovieMethodOnFrontend('PRESS_SHIFT_DEPTH') then
                        ScaleformMovieMethodAddParamInt(1)
                        EndScaleformMovieMethod()
                        mapExpandAt = nil
                    end
                end
                if now >= nextBranding then nativeBranding(); nextBranding = now + 250 end
                if GetPauseMenuState() == 15 and (nativeRoute ~= 'map' or mapExpandAt == nil) then finishTransition() end
                if nativeRoute == 'map' then
                    DisableControlAction(0, 205, true)
                    DisableControlAction(0, 206, true)
                    DisableControlAction(2, 205, true)
                    DisableControlAction(2, 206, true)
                end
            elseif nativeSeen then
                nativePending = false
                finishTransition()
                cooldown = now + 350
                if config.returnFromNative ~= false then openMenu() end
            elseif now > nativeDeadline then
                nativePending = false
                finishTransition()
                openMenu()
                SendNUIMessage({ action = 'coii:quick:error', text = 'The native menu did not open. Try again.' })
            end
        elseif available() and not IsPauseMenuActive() and not IsWarningMessageActive() and not IsNuiFocused() then
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableFrontendThisFrame()
            if now > cooldown and (IsDisabledControlJustReleased(0, 200) or IsDisabledControlJustReleased(0, 199)) then
                openMenu()
            end
        end
        setHudHidden(framework.IsPlayerLoaded() == true and (open or nativePending or IsPauseMenuActive() or IsWarningMessageActive()))
        Wait(0)
    end
end)

AddEventHandler('onClientResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    stopped = true
    nativePending = false
    finishTransition()
    closeMenu()
    setHudHidden(false)
end)
