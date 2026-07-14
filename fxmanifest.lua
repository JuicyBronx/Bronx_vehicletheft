fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Bronx Connection RP'
description 'Furto veicolo: ped incarico, sblocco tablet/lockpick, dispatch, consegna con valigetta'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'pcb_minigame',
}
