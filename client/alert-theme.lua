local stopped, movie = false, nil
CreateThread(function()
    movie = RequestScaleformMovie('POPUP_WARNING')
    while not stopped do
        if movie and movie ~= 0 and HasScaleformMovieLoaded(movie) then
            if BeginScaleformMovieMethod(movie, 'COII_SET_ALERT_THEME') then
                local bg = CoiiTheme.background
                ScaleformMovieMethodAddParamInt(bg.r * 65536 + bg.g * 256 + bg.b)
                ScaleformMovieMethodAddParamInt(CoiiTheme.r * 65536 + CoiiTheme.g * 256 + CoiiTheme.b)
                EndScaleformMovieMethod()
            end
        end
        Wait(500)
    end
end)
AddEventHandler('onClientResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    stopped = true
    if movie and movie ~= 0 then SetScaleformMovieAsNoLongerNeeded(movie) end
end)
