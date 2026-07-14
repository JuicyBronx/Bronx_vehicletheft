--========================================================
--  bronx_furtoveicolo - client/main.lua
--========================================================

local pedEntity   = nil
local pedBlip     = nil
local targetVeh   = nil
local consegnaBlip= nil
local consegnaAttiva = false
local sbloccoInCorso = false

local function notify(msg, kind)
    lib.notify({ description = msg, type = kind or 'inform' })
end

local function countItem(name)
    local n = exports.ox_inventory:Search('count', name)
    return tonumber(n) or 0
end

-- ========================================================
--  PED che assegna il furto (+ blip)
-- ========================================================
CreateThread(function()
    local m = joaat(Config.Ped.model)
    RequestModel(m)
    local t = GetGameTimer()
    while not HasModelLoaded(m) and GetGameTimer() - t < 5000 do Wait(10) end
    if not HasModelLoaded(m) then return end

    local c = Config.Ped.coords
    pedEntity = CreatePed(4, m, c.x, c.y, c.z - 1.0, c.w, false, true)
    FreezeEntityPosition(pedEntity, true)
    SetEntityInvincible(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    if Config.Ped.scenario then TaskStartScenarioInPlace(pedEntity, Config.Ped.scenario, 0, true) end
    SetModelAsNoLongerNeeded(m)

    if Config.Ped.blip and Config.Ped.blip.enabled then
        pedBlip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(pedBlip, Config.Ped.blip.sprite)
        SetBlipColour(pedBlip, Config.Ped.blip.color)
        SetBlipScale(pedBlip, Config.Ped.blip.scale)
        SetBlipAsShortRange(pedBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Ped.blip.label)
        EndTextCommandSetBlipName(pedBlip)
    end

    exports.ox_target:addLocalEntity(pedEntity, {
        {
            name = 'bronx_furto_parla',
            label = 'Parla col contatto',
            icon = 'fas fa-comment',
            distance = 2.5,
            onSelect = function() parlaColPed() end,
        },
    })
end)

function parlaColPed()
    notify('Il mio contatto mi ha dato delle coordinate. Vai li\' e ruba l\'auto.', 'inform')
    Wait(1800)
    notify('Non scordare il Tablet Sblocco (veloce) o un lockpick (lento).', 'inform')
    TriggerServerEvent('bronx_furtoveicolo:richiedi')
end

-- ========================================================
--  Ricevo l'auto da rubare: spawn + waypoint + target sblocco
-- ========================================================
RegisterNetEvent('bronx_furtoveicolo:vaiAllAuto', function(model, spawn)
    local m = joaat(model)
    RequestModel(m)
    local t = GetGameTimer()
    while not HasModelLoaded(m) and GetGameTimer() - t < 5000 do Wait(10) end
    if not HasModelLoaded(m) then notify('Errore spawn veicolo.', 'error'); return end

    targetVeh = CreateVehicle(m, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetVehicleDoorsLocked(targetVeh, 2)          -- bloccata
    SetVehicleNumberPlateText(targetVeh, 'FURTO')
    SetVehicleOnGroundProperly(targetVeh)
    SetModelAsNoLongerNeeded(m)

    SetNewWaypoint(spawn.x, spawn.y)
    notify('Coordinate ricevute: raggiungi il veicolo.', 'success')

    exports.ox_target:addLocalEntity(targetVeh, {
        {
            name = 'bronx_furto_sblocca',
            label = 'Sblocca veicolo',
            icon = 'fas fa-unlock',
            distance = 2.0,
            canInteract = function(entity)
                return GetVehicleDoorLockStatus(entity) == 2 and not sbloccoInCorso
            end,
            onSelect = function() scegliMetodo() end,
        },
    })
end)

-- ========================================================
--  Scelta metodo di sblocco
-- ========================================================
function scegliMetodo()
    if not targetVeh or not DoesEntityExist(targetVeh) then return end
    local hasTablet = countItem(Config.Items.tablet) > 0
    local hasLp     = countItem(Config.Items.lockpick) > 0

    lib.registerContext({
        id = 'bronx_furto_metodo',
        title = 'Sblocco Veicolo',
        options = {
            {
                title = 'Tablet Sblocco',
                description = hasTablet and 'Veloce (hacking)' or 'Non hai il Tablet Sblocco',
                icon = 'fas fa-tablet-screen-button',
                disabled = not hasTablet,
                onSelect = function() avviaSblocco('tablet') end,
            },
            {
                title = 'Lockpick',
                description = hasLp and 'Lento (grimaldello)' or 'Non hai il lockpick',
                icon = 'fas fa-screwdriver',
                disabled = not hasLp,
                onSelect = function() avviaSblocco('lockpick') end,
            },
        },
    })
    lib.showContext('bronx_furto_metodo')
end

-- ========================================================
--  Avvio sblocco: allarme + dispatch + minigame
-- ========================================================
function avviaSblocco(metodo)
    if sbloccoInCorso then return end
    if not targetVeh or not DoesEntityExist(targetVeh) then return end
    sbloccoInCorso = true

    if Config.Sblocco.suonaAllarme then
        SetVehicleAlarm(targetVeh, true)
        StartVehicleAlarm(targetVeh)
    end

    -- dispatch sull'ULTIMA POSIZIONE (coords del veicolo, fisse)
    local vc = GetEntityCoords(targetVeh)
    TriggerServerEvent('bronx_furtoveicolo:tentativo', vc.x, vc.y, vc.z)

    if metodo == 'tablet' then
        exports.pcb_minigame:startMinigame(
            Config.Sblocco.tablet.solderCount,
            Config.Sblocco.tablet.seconds,
            function(success) esitoSblocco(success, 'tablet') end
        )
    else
        local ok = lib.skillCheck(Config.Sblocco.lockpick.difficulty, Config.Sblocco.lockpick.inputs)
        esitoSblocco(ok, 'lockpick')
    end
end

function esitoSblocco(success, metodo)
    sbloccoInCorso = false
    if targetVeh and DoesEntityExist(targetVeh) then
        SetVehicleAlarm(targetVeh, false)
    end

    if success then
        SetVehicleDoorsLocked(targetVeh, 1)   -- sbloccata
        notify('Veicolo sbloccato!', 'success')
        if targetVeh and DoesEntityExist(targetVeh) then
            exports.ox_target:removeLocalEntity(targetVeh, 'bronx_furto_sblocca')
        end
        TriggerServerEvent('bronx_furtoveicolo:sbloccato')
    else
        notify('Sblocco fallito.', 'error')
        if metodo == 'lockpick' and Config.ConsumaLockpickSuFail then
            TriggerServerEvent('bronx_furtoveicolo:consumaLockpick')
        end
    end
end

-- ========================================================
--  GPS di consegna (arriva dopo il delay server)
-- ========================================================
RegisterNetEvent('bronx_furtoveicolo:gpsConsegna', function()
    local c = Config.Consegna.coords
    SetNewWaypoint(c.x, c.y)
    consegnaBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipColour(consegnaBlip, 5)
    SetBlipRoute(consegnaBlip, true)
    SetBlipRouteColour(consegnaBlip, 5)
    notify('Nuove coordinate: consegna il veicolo.', 'inform')
    consegnaAttiva = true

    CreateThread(function()
        while consegnaAttiva do
            local p = GetEntityCoords(PlayerPedId())
            local dist = #(p - vector3(c.x, c.y, c.z))
            if dist < 60.0 then
                -- marker a terra, visibile da lontano
                DrawMarker(1, c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    3.0, 3.0, 1.2, 63, 246, 246, 160, false, false, 2, false, nil, nil, false)
                if dist < 8.0 then
                    consegnaAttiva = false
                    if consegnaBlip then RemoveBlip(consegnaBlip); consegnaBlip = nil end
                    consegnaCinematica()
                    break
                end
                Wait(0)
            else
                Wait(800)
            end
        end
    end)
end)

-- ========================================================
--  Cinematica: NPC consegna la valigetta
-- ========================================================
function consegnaCinematica()
    local c = Config.Consegna.coords
    local ped = PlayerPedId()

    -- se arriva in auto, lo faccio scendere prima della cinematica
    local vehIn = GetVehiclePedIsIn(ped, false)
    if vehIn ~= 0 then
        TaskLeaveVehicle(ped, vehIn, 0)
        local lt = GetGameTimer()
        while GetVehiclePedIsIn(ped, false) ~= 0 and GetGameTimer() - lt < 3000 do Wait(50) end
        Wait(400)
    end

    local m = joaat(Config.Consegna.npcModel)
    RequestModel(m)
    local t = GetGameTimer()
    while not HasModelLoaded(m) and GetGameTimer() - t < 5000 do Wait(10) end

    local npc = CreatePed(4, m, c.x, c.y, c.z - 1.0, c.w, false, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(m)

    ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, npc, 1000)
    Wait(800)

    RequestAnimDict('mp_common')
    local at = GetGameTimer()
    while not HasAnimDictLoaded('mp_common') and GetGameTimer() - at < 3000 do Wait(10) end
    TaskPlayAnim(npc, 'mp_common', 'givetake1_a', 8.0, -8.0, -1, 48, 0, false, false, false)
    TaskPlayAnim(ped, 'mp_common', 'givetake1_b', 8.0, -8.0, -1, 48, 0, false, false, false)

    Wait((Config.Tempi.attesaNpcConsegna or 6) * 1000)

    ClearPedTasks(ped)
    if DoesEntityExist(npc) then DeleteEntity(npc) end

    -- l'auto rubata sparisce: il player non puo' riprenderla
    if targetVeh and DoesEntityExist(targetVeh) then
        SetEntityAsMissionEntity(targetVeh, true, true)
        DeleteEntity(targetVeh)
    end
    targetVeh = nil

    TriggerServerEvent('bronx_furtoveicolo:consegna')
end

-- ========================================================
RegisterNetEvent('bronx_furtoveicolo:notify', function(msg, kind)
    notify(msg, kind)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    consegnaAttiva = false
    if pedEntity and DoesEntityExist(pedEntity) then DeleteEntity(pedEntity) end
    if pedBlip then RemoveBlip(pedBlip) end
    if consegnaBlip then RemoveBlip(consegnaBlip) end
end)