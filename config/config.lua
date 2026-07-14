Config = {}

-- =====================================================================
--  bronx_furtoveicolo - CONFIG
-- =====================================================================

-- ------- ITEM (ox_inventory) -------
Config.Items = {
    tablet   = 'hacking',   -- Tablet Sblocco (veloce, minigame PCB)
    lockpick = 'lockpick',      -- gia' esistente (lento, skillcheck ox_lib)
}
Config.ConsumaLockpickSuFail = true   -- se true, il lockpick si consuma anche se fallisci
Config.ConsumaTablet         = false  -- il tablet e' riutilizzabile

-- ------- SOLDI -------
Config.MoneyAccount = 'black_money'   -- account soldi sporchi

-- ------- TEMPI (secondi) -------
Config.Tempi = {
    cooldownFurto   = 40 * 60,   -- 40 minuti tra un furto e l'altro (per player)
    delayGpsConsegna = 1 * 60,   -- attesa dopo aver rubato prima di ricevere il GPS di consegna
    dispatchBlipDurata = 90,     -- quanti secondi resta il blip dispatch sull'ULTIMA posizione
    attesaNpcConsegna = 6,       -- durata cinematica scambio valigetta con l'NPC
}

-- ------- PED che assegna il furto -------
Config.Ped = {
    model  = 's_m_y_dealer_01',
    coords = vector4(-905.27, -2337.50, 6.71, 323.88),
    scenario = 'WORLD_HUMAN_AA_SMOKE',
    blip = {
        enabled = true,
        sprite  = 280,     -- icona
        color   = 1,       -- rosso
        scale   = 0.9,
        label   = 'Contatto Furti',
    },
}

-- ------- PUNTI DI SPAWN AUTO -------
-- !!! DA SOSTITUIRE: ora sono tutti uguali al ped (placeholder). Metti i punti
--     REALI dove vuoi che spawni l'auto da rubare. Ne viene scelto uno a caso.
Config.SpawnAuto = {
    vector4(917.30, -41.72, 78.76, 241.34),  -- <-- CAMBIA
    vector4(-1664.74, -301.54, 51.55, 52.11),  -- <-- CAMBIA
    vector4(-1821.61, 782.57, 137.88, 41.26),  -- <-- CAMBIA
    vector4(-1664.74, -301.54, 51.55, 52.11),  -- <-- CAMBIA
}

-- ------- PUNTO DI CONSEGNA (NPC valigetta) -------
-- !!! DA INSERIRE: la coordinata dove il player consegna e riceve i soldi.
Config.Consegna = {
    coords   = vector4(1266.68, -3300.73, 5.90, 206.81),  -- <-- INSERISCI
    npcModel = 's_m_m_highsec_01',
    blipLabel = 'Consegna',
}

-- ------- VEICOLI (percentuale spawn + soldi sporchi) -------
-- weight = probabilita' relativa (la somma fa 100 ma non e' obbligatorio)
Config.Veicoli = {
    { model = 'sultan3',    weight = 45, reward = 13000 },
    { model = 'dominator',  weight = 30, reward = 18000 },
    { model = 'faction2',   weight = 15, reward = 15000 },
    { model = 'khamelion',  weight = 5,  reward = 25000 },
    { model = 'comet6',     weight = 5,  reward = 27000 },
}

-- ------- SBLOCCO (minigame) -------
Config.Sblocco = {
    -- TABLET: minigame PCB (pcb_minigame). "Veloce": un colpo, tempo generoso.
    tablet = {
        solderCount = 3,   -- 1-7 (difficolta')
        seconds     = 28,
    },
    -- LOCKPICK: skillcheck ox_lib in sequenza. "Lento".
    lockpick = {
        difficulty = { 'easy', 'easy', 'medium', 'hard' },  -- 4 check in fila
        inputs     = { 'w', 'a', 's', 'd' },
    },
    -- allarme auto durante lo sblocco
    suonaAllarme = true,
}

-- ------- DISPATCH (verso juicy_police) -------
-- Il segnale arriva SULL'ULTIMA POSIZIONE dello sblocco, non insegue il player
-- (si passano coordinate fisse a CreateDispatch).
Config.Dispatch = {
    code        = '10-72',
    title       = 'Tentato Furto Veicolo',
    description = 'Allarme veicolo: tentativo di sblocco in corso',
    color       = '#e0b53f',
}

Config.Debug = false
