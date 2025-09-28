Config = {}

-- Framework Detection
Config.Framework = 'qb-core' -- 'qb-core' or 'qbox'

-- Integrations
Config.Integrations = {
    Police = 'wasabi_police',
    Ambulance = 'wasabi_ambulance',
    Banking = 'codm-banking', -- 'okokBanking', 'qb-banking', 'codm-banking', 'qb-management'
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
        permissions = {'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 'create_warrants', 'view_custody', 'manage_custody'}
    },
    ['ambulance'] = {
        grades = {0, 1, 2, 3, 4},
        permissions = {'view_people', 'view_medical', 'create_medical_incidents', 'manage_medical_records'}
    },
    ['sheriff'] = {
        grades = {0, 1, 2, 3, 4, 5},
        permissions = {'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 'create_warrants', 'view_custody', 'manage_custody'}
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
    camera_coords = vector4(402.91665649414, -995.75970458984, -98.5, 186.22036743164),
    upload_url = 'https://api.imgur.com/3/image', -- Change this to your preferred image upload service
    upload_headers = {
        ['Authorization'] = 'Client-ID YOUR_IMGUR_CLIENT_ID' -- Replace with your actual API key
    }
}

-- Fine Payment Locations
Config.FinePaymentLocations = {
    {
        coords = vector3(442.0, -981.0, 30.7),
        label = "LSPD Station"
    },
    {
        coords = vector3(1853.0, 3689.0, 34.3),
        label = "Sandy Shores Sheriff"
    },
    {
        coords = vector3(-447.0, 6013.0, 31.7),
        label = "Paleto Bay Sheriff"
    }
}

-- Medical Record Flags
Config.MedicalFlags = {
    {
        id = "allergies",
        label = "Allergies",
        description = "Patient has significant allergies",
        color = "red"
    },
    {
        id = "heart_condition",
        label = "Heart Condition",
        description = "Patient has a heart condition",
        color = "red"
    },
    {
        id = "diabetes",
        label = "Diabetes",
        description = "Patient has diabetes",
        color = "orange"
    },
    {
        id = "epilepsy",
        label = "Epilepsy",
        description = "Patient has epilepsy",
        color = "orange"
    },
    {
        id = "asthma",
        label = "Asthma",
        description = "Patient has asthma",
        color = "yellow"
    },
    {
        id = "dnr",
        label = "DNR",
        description = "Do Not Resuscitate order in place",
        color = "purple"
    },
    {
        id = "mental_health",
        label = "Mental Health",
        description = "Patient has mental health conditions",
        color = "blue"
    },
    {
        id = "pregnant",
        label = "Pregnant",
        description = "Patient is pregnant",
        color = "pink"
    }
}

-- Custody Cell Locations
Config.CustodyCells = {
    {
        id = 1,
        label = "Cell 1",
        coords = vector3(460.0, -994.0, 24.9)
    },
    {
        id = 2,
        label = "Cell 2",
        coords = vector3(457.0, -994.0, 24.9)
    },
    {
        id = 3,
        label = "Cell 3",
        coords = vector3(454.0, -994.0, 24.9)
    },
    {
        id = 4,
        label = "Cell 4",
        coords = vector3(450.0, -994.0, 24.9)
    }
}

-- Department Accounts
Config.DepartmentAccounts = {
    ['police'] = {
        label = "Los Santos Police Department",
        account = "police"
    },
    ['sheriff'] = {
        label = "Blaine County Sheriff's Office",
        account = "sheriff"
    },
    ['ambulance'] = {
        label = "Emergency Medical Services",
        account = "ambulance"
    }
}

-- Audit Log Settings
Config.AuditLog = {
    enabled = true,
    retention_days = 30, -- How many days to keep audit logs
    log_actions = {
        'search_person',
        'search_vehicle',
        'create_incident',
        'update_incident',
        'issue_fine',
        'create_warrant',
        'update_warrant',
        'create_custody',
        'release_custody',
        'create_medical_record',
        'update_medical_record',
        'take_mugshot',
        'take_evidence_photo',
        'update_person',
        'update_vehicle'
    }
}

-- UI Themes
Config.UIThemes = {
    ['police'] = {
        primary_color = "#1a3c6e",
        secondary_color = "#2c5ba3",
        accent_color = "#4287f5",
        text_color = "#ffffff",
        background_color = "#0a1e37"
    },
    ['ambulance'] = {
        primary_color = "#8b0000",
        secondary_color = "#b22222",
        accent_color = "#ff0000",
        text_color = "#ffffff",
        background_color = "#400000"
    }
}