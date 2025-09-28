Config = {}

-- Framework Detection
Config.Framework = 'qb-core' -- 'qb-core' or 'qbox'

-- Integrations
Config.Integrations = {
    Police = 'wasabi_police',
    Ambulance = 'wasabi_ambulance',
    Banking = 'okokBanking', -- 'okokBanking', 'qb-banking', 'codm-banking', 'qb-management'
    Dispatch = 'custom', -- 'rcore', 'ps-dispatch', 'custom'
    Inventory = 'qb-inventory',
    Roster = 'fiveroster'
}

-- Tablet Item
Config.TabletItem = 'zmdt_tablet'

-- Jobs with MDT Access
Config.AuthorizedJobs = {
    ['police'] = {
        grades = {0, 1, 2, 3, 4, 5},
        permissions = {'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 'create_warrants'}
    },
    ['ambulance'] = {
        grades = {0, 1, 2, 3, 4},
        permissions = {'view_people', 'view_medical', 'create_medical_incidents'}
    },
    ['sheriff'] = {
        grades = {0, 1, 2, 3, 4, 5},
        permissions = {'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 'create_warrants'}
    }
}

-- Discord Webhooks
Config.Webhooks = {
    fines = '',
    incidents = '',
    warrants = '',
    custody = '',
    medical = ''
}

-- Google Sheets Integration
Config.GoogleSheets = {
    enabled = false,
    webhook_url = ''
}

-- Banking Configuration
Config.Banking = {
    account_type = 'bank', -- 'bank' or 'cash'
    fine_account = 'government'
}

-- Blip Settings
Config.Blips = {
    fine_payment = {
        sprite = 207,
        color = 1,
        scale = 0.8,
        label = 'Pay Fine'
    },
    incident = {
        sprite = 161,
        color = 1,
        scale = 0.9,
        label = 'Incident Location'
    }
}

-- Mugshot Settings
Config.Mugshot = {
    coords = vector4(402.91665649414, -996.75970458984, -99.000259399414, 186.22036743164),
    camera_coords = vector4(402.91665649414, -995.75970458984, -98.5, 186.22036743164)
}
