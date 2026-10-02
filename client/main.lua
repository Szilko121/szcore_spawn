local spawning = false
local spawnedCitizen = nil

local function loadPlayerModel(modelName)
    local model = type(modelName) == 'number' and modelName or joaat(modelName)

    if not IsModelInCdimage(model) or not IsModelValid(model) or not IsModelAPed(model) then
        return nil, 'invalid_model'
    end

    RequestModel(model)
    local deadline = GetGameTimer() + 10000

    while not HasModelLoaded(model) do
        if GetGameTimer() >= deadline then
            return nil, 'model_timeout'
        end

        RequestModel(model)
        Wait(0)
    end

    return model
end

local function finishSpawn(data)
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    ClearPedTasksImmediately(ped)

    spawnedCitizen = data.citizenid
    spawning = false

    TriggerEvent('szcore:client:spawned', data)

    if IsScreenFadedOut() then
        DoScreenFadeIn(600)
    end
end

local function spawnCharacter(data)
    if spawning or not data or not data.citizenid or spawnedCitizen == data.citizenid then
        return
    end

    spawning = true

    CreateThread(function()
        local p = data.position or SzCoreConfig.DefaultPosition
        local modelName = data.charinfo and data.charinfo.gender == 'female'
            and 'mp_f_freemode_01'
            or 'mp_m_f_freemode_01'

        local model, modelError = loadPlayerModel(modelName)

        if not model then
            print(('[szcore_spawn] Failed to load player model %s: %s'):format(
                tostring(modelName),
                tostring(modelError)
            ))

            model = joaat('mp_m_freemode_01')
            RequestModel(model)

            local fallbackDeadline = GetGameTimer() + 5000
            while not HasModelLoaded(model) and GetGameTimer() < fallbackDeadline do
                RequestModel(model)
                Wait(0)
            end

            if not HasModelLoaded(model) then
                spawning = false
                TriggerEvent('szcore:client:spawnFailed', 'model_load_failed')
                DoScreenFadeIn(300)
                return
            end
        end

        local spawn = {
            x = tonumber(p.x) or SzCoreConfig.DefaultPosition.x,
            y = tonumber(p.y) or SzCoreConfig.DefaultPosition.y,
            z = tonumber(p.z) or SzCoreConfig.DefaultPosition.z,
            heading = tonumber(p.w) or SzCoreConfig.DefaultPosition.w,
            model = model,
            skipFade = true
        }

        RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)

        local callbackFired = false

        exports.spawnmanager:spawnPlayer(spawn, function()
            callbackFired = true
            SetModelAsNoLongerNeeded(model)
            finishSpawn(data)
        end)

        local deadline = GetGameTimer() + 15000

        while spawning and not callbackFired and GetGameTimer() < deadline do
            Wait(100)
        end

        if spawning and not callbackFired then
            print(('[szcore_spawn] spawnmanager timeout for citizen %s'):format(
                tostring(data.citizenid)
            ))

            local ped = PlayerPedId()
            SetPlayerModel(PlayerId(), model)
            ped = PlayerPedId()

            SetEntityCoordsNoOffset(
                ped,
                spawn.x,
                spawn.y,
                spawn.z,
                false,
                false,
                false,
                true
            )

            NetworkResurrectLocalPlayer(
                spawn.x,
                spawn.y,
                spawn.z,
                spawn.heading,
                true,
                true,
                false
            )

            SetModelAsNoLongerNeeded(model)
            finishSpawn(data)
        end
    end)
end

AddEventHandler('szcore:client:onPlayerLoaded', spawnCharacter)

AddEventHandler('szcore:client:onPlayerUnloaded', function()
    spawnedCitizen = nil
    spawning = false
end)

CreateThread(function()
    Wait(1200)

    if exports.szcore:IsPlayerLoaded() then
        spawnCharacter(exports.szcore:GetPlayerData())
    end
end)
