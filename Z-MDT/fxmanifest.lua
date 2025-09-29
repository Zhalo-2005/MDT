fx_version 'cerulean'
game 'gta5'

author 'Zalo'
description 'Z-MDT System - Enhanced QBCore Integration'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config_improved.lua',
    'shared/charges.lua',
    'shared/items.lua'
}

client_scripts {
    'client/main_improved.lua',
    'client/dispatch.lua',
    'client/medical.lua',
    'client/mugshot.lua',
    'client/payments.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main_improved.lua',
    'server/jail.lua',
    'server/audit.lua',
    'server/custody.lua',
    'server/departments.lua',
    'server/fines.lua',
    'server/medical.lua'
}

ui_page 'web/index_improved.html'

files {
    'web/index_improved.html',
    'web/js/main_improved.js',
    'web/css/style.css',
    'web/assets/*.png',
    'zmdt_tablet.png'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib'
}

escrow_ignore {
    'shared/config_improved.lua',
    'shared/charges.lua',
    'shared/items.lua',
    'sql/*.sql',
    'README.md',
    'INSTALL.md'
}