fx_version 'cerulean'
game 'gta5'

author 'Z-Development'
description 'Z-MDT - UK-Based Police Mobile Data Terminal'
version '1.3.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'shared/config.lua',
    'shared/charges.lua',
    'shared/items.lua'
}

client_scripts {
    'client/main.lua',
    'client/mugshot.lua',
    'client/dispatch.lua',
    'client/payments.lua',
    'client/medical.lua'
}

    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/audit.lua',
    'server/custody.lua',
    'server/departments.lua',
    'server/fines.lua',
    'server/medical.lua'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/auto_sql.lua',
    'server/main.lua',
    'server/audit.lua',
    'server/custody.lua',
    'server/departments.lua',
    'server/fines.lua',
    'server/medical.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/js/main.js',
    'web/assets/*.png',
    'web/assets/*.jpg',
    'web/assets/*.svg'
}

dependencies {
    'qb-core',
    'oxmysql',
    'screenshot-basic'
}

exports {
    'TakeMugshot',
    'TakeEvidencePhoto',
    'CreateDispatchCall',
    'OpenMedicalTablet',
    'CreateMedicalIncident'
}

server_exports {
    'LogAction',
    'IsDepartmentManager'
}