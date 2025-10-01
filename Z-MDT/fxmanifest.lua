fx_version 'cerulean'
game 'gta5'

author 'Z-Development'
description 'Z-MDT System - Purple/Blue Theme Edition'
version '3.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/items.lua'
}

client_scripts {
    'client/main_improved.lua',
    'client/medical.lua',
    'client/payments.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main_improved.lua',
    'server/jail.lua',
    'server/fines.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/js/zmdt-main.js',
    'web/css/zmdt-style.css',
    'web/assets/*.png'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib'
}

escrow_ignore {
    'shared/config.lua',
    'shared/items.lua',
    'README.md',
    'INSTALL.md'
}