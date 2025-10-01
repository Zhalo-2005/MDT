fx_version 'cerulean'
game 'gta5'

author 'Z-MDT Development Team'
description 'Advanced Police MDT System with Tablet Support'
version '3.0.0'

-- Resource Metadata
lua54 'yes'
use_fxv2_oal 'yes'

-- Files
shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locales.lua'
}

client_scripts {
    'client/main.lua',
    'client/jail.lua',
    'client/fines.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/jail.lua',
    'server/fines.lua'
}

-- UI Files
ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/*.css',
    'web/js/*.js',
    'web/images/*.png',
    'web/images/*.jpg',
    'web/fonts/*.ttf',
    'web/fonts/*.woff',
    'web/fonts/*.woff2'
}

-- Dependencies
dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib'
}

-- Optional Dependencies (for enhanced features)
dependency_overrides {
    ['okokBanking'] = 'optional',
    ['qb-banking'] = 'optional',
    ['qb-management'] = 'optional',
    ['codm-banking'] = 'optional'
}

-- Exports
exports {
    'OpenMDT',
    'CloseMDT',
    'IsMDTOpen'
}

-- Server Exports
server_exports {
    'GetCitizenData',
    'GetVehicleData',
    'GetIncidentData'
}

-- Convars
convar_category 'Z-MDT Configuration' {
    "Use Tablet Item", "zmdt_use_tablet", "CV_BOOL", "true",
    "Restrict to Vehicle", "zmdt_restrict_vehicle", "CV_BOOL", "false",
    "Default Key", "zmdt_default_key", "CV_STRING", "F6"
}

-- Compatibility
provide 'zmdt'