--========================================================
--  bronx_furtoveicolo - server/main.lua
--  Logica AUTOREVOLE: cooldown, scelta veicolo per percentuale,
--  ricompensa, dispatch. Il client non decide veicolo ne' soldi.
--========================================================

local ESX = exports['es_extended']:getSharedObject()

local active    = {}   -- [identifier] = { model, reward, stage, }
local lastFurto = {}   -- [identifier] = os.time()

local function notify(src, msg, kind)
    TriggerClientEvent('bronx_furtoveicolo:notify', src, msg, kind or 'inform')
end

-- scelta veicolo pesata (server-side)
local function weightedPick()
    local total = 0
    for _, v in ipairs(Config.Veicoli) do total = total + (v.weight or 0) end
    if total <= 0 then return Config.Veicoli[1] end
    local r = math.random() * total
    local acc = 0
    for _, v in ipairs(Config.Veicoli) do
        acc = acc + (v.weight or 0)
        if r <= acc then return v end
    end
    return Config.Veicoli[#Config.Veicoli]
end

-- il player parla col ped e richiede un furto
RegisterNetEvent('bronx_furtoveicolo:richiedi', function()
    local src = source
    local xP = ESX.GetPlayerFromId(src); if not xP then return end
    local id = xP.identifier
    local now = os.time()

    if active[id] then
        notify(src, 'Hai gia\' un furto in corso.', 'error'); return
    end
    if lastFurto[id] and (now - lastFurto[id]) < Config.Tempi.cooldownFurto then
        local rem = Config.Tempi.cooldownFurto - (now - lastFurto[id])
        notify(src, ('Devi aspettare ancora %d minuti.'):format(math.ceil(rem / 60)), 'error')
        return
    end

    local veh   = weightedPick()
    local spawn = Config.SpawnAuto[math.random(#Config.SpawnAuto)]
    active[id]  = { model = veh.model, reward = veh.reward, stage = 'toCar' }
    lastFurto[id] = now

    TriggerClientEvent('bronx_furtoveicolo:vaiAllAuto', src, veh.model, spawn)
end)

-- il client avvia lo sblocco -> dispatch SULL'ULTIMA POSIZIONE (coords fisse)
RegisterNetEvent('bronx_furtoveicolo:tentativo', function(x, y, z)
    local src = source
    local xP = ESX.GetPlayerFromId(src); if not xP then return end
    if not active[xP.identifier] then return end
    pcall(function()
        exports['juicy_police']:CreateDispatch({
            code        = Config.Dispatch.code,
            title       = Config.Dispatch.title,
            description = Config.Dispatch.description,
            color       = Config.Dispatch.color,
            x = x + 0.0, y = y + 0.0, z = z + 0.0,
        })
    end)
end)

-- sblocco riuscito: dopo il delay, mando il GPS di consegna
RegisterNetEvent('bronx_furtoveicolo:sbloccato', function()
    local src = source
    local xP = ESX.GetPlayerFromId(src); if not xP then return end
    local id = xP.identifier
    local a = active[id]
    if not a or a.stage ~= 'toCar' then return end
    a.stage = 'rubata'

    SetTimeout(Config.Tempi.delayGpsConsegna * 1000, function()
        local cur = active[id]
        if not cur or cur.stage ~= 'rubata' then return end
        cur.stage = 'toConsegna'
        local ply = ESX.GetPlayerFromIdentifier(id)
        if ply then TriggerClientEvent('bronx_furtoveicolo:gpsConsegna', ply.source) end
    end)
end)

-- consegna: accredito i soldi sporchi decisi dal server
RegisterNetEvent('bronx_furtoveicolo:consegna', function()
    local src = source
    local xP = ESX.GetPlayerFromId(src); if not xP then return end
    local id = xP.identifier
    local a = active[id]
    if not a or a.stage ~= 'toConsegna' then return end

    xP.addAccountMoney(Config.MoneyAccount, a.reward)
    active[id] = nil
    notify(src, ('Consegna completata: +%d$ sporchi.'):format(a.reward), 'success')
end)

-- consumo lockpick su fallimento (opzionale)
RegisterNetEvent('bronx_furtoveicolo:consumaLockpick', function()
    local src = source
    exports.ox_inventory:RemoveItem(src, Config.Items.lockpick, 1)
end)

-- pulizia alla disconnessione
AddEventHandler('esx:playerDropped', function(src)
    local xP = ESX.GetPlayerFromId(src)
    if xP then active[xP.identifier] = nil end
end)
