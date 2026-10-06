if Config.Debug ~= true then return end

CreateThread(function()
    while not IsPauseMenuActive() do Wait(500) end

    local movie = RequestScaleformMovie('PAUSE_MENU_INSTRUCTIONAL_BUTTONS')
    local deadline = GetGameTimer() + 5000
    while not HasScaleformMovieLoaded(movie) and GetGameTimer() < deadline do
        Wait(0)
    end

    if not HasScaleformMovieLoaded(movie) then
        print('[coii_nativeui] Native pause UI check: movie load timed out.')
        SetScaleformMovieAsNoLongerNeeded(movie)
        return
    end

    local build = nil
    if BeginScaleformMovieMethod(movie, 'COII_GET_BUILD') then
        local result = EndScaleformMovieMethodReturnValue()
        deadline = GetGameTimer() + 2000
        while not IsScaleformMovieMethodReturnValueReady(result) and GetGameTimer() < deadline do
            Wait(0)
        end
        if IsScaleformMovieMethodReturnValueReady(result) then
            build = GetScaleformMovieMethodReturnValueInt(result)
        end
    end

    SetScaleformMovieAsNoLongerNeeded(movie)
    if build == 994 then
        print('[coii_nativeui] Native pause UI check: custom Scaleform build 994 loaded.')
    else
        print('[coii_nativeui] Native pause UI check: custom build marker missing. Fully exit FiveM and launch again with this resource running; a resource restart may retain the old frontend movie.')
    end
end)
