local spawning = false
local spawnedCitizen = nil

local function spawnCharacter(data)
    if spawning or not data or not data.citizenid or spawnedCitizen == data.citizenid then return end
    spawning = true
    local p = data.position or SzCoreConfig.DefaultPosition
    local model = data.charinfo and data.charinfo.gender == 'female' and 'mp_f_freemode_01' or 'mp_m_f_freemode_01'
    exports.spawnmanager:spawnPlayer({
        x = tonumber(p.x) or SzCoreConfig.DefaultPosition.x,
        y = tonumber(p.y) or SzCoreConfig.DefaultPosition.y,
        z = tonumber(p.z) or SzCoreConfig.DefaultPosition.z,
        heading = tonumber(p.w) or SzCoreConfig.DefaultPosition.w,
        model = model,
        skipFade = true
    }, function()
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        ClearPedTasksImmediately(ped)
        spawnedCitizen = data.citizenid
        TriggerEvent('szcore:client:spawned', data)
        DoScreenFadeIn(600)
        spawning = false
    end)
end

AddEventHandler('szcore:client:onPlayerLoaded', spawnCharacter)
AddEventHandler('szcore:client:onPlayerUnloaded', function() spawnedCitizen = nil end)
CreateThread(function()
    Wait(1200)
    if exports.szcore:IsPlayerLoaded() then spawnCharacter(exports.szcore:GetPlayerData()) end
end)
