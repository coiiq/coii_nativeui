RegisterNetEvent('coii_nativeui:disconnect', function()
    local player = tonumber(source)
    if not player or player <= 0 then return end
    DropPlayer(player, 'You disconnected from the server.')
end)
