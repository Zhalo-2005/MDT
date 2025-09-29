Config = {}

-- Framework Detection
Config.Framework = 'qb-core' -- 'qb-core' or 'qbox'

-- Database Configuration
Config.Database = {
    UseSync = true, -- Use synchronous queries for better reliability
    Debug = false   -- Enable debug logging
}

-- Integrations
Config.Integrations = {
    Police = 'wasabi_police',      -- 'wasabi_police', 'qb-police', 'custom'
    Ambulance = 'wasabi_ambulance', -- 'wasabi_ambulance', 'qb-ambulance', 'custom'
    Banking = 'codm-banking',      -- 'okokBanking', 'qb-banking', 'codm-banking', 'qb-management'
    Dispatch = 'custom',           -- 'rcore', 'ps-dispatch', 'custom', 'disabled'
    Inventory = 'qb-inventory',    -- 'qb-inventory', 'ox_inventory', 'codm-inventory'
    Roster = 'fiveroster'          -- 'fiveroster', 'disabled'
}

-- Tablet Item
Config.TabletItem = 'zmdt_tablet'

-- Job Configuration - Simplified PD vs Ambulance detection
Config.Jobs = {
    -- Police Departments (all ranks have same access)
    PoliceJobs = {
        'police', 'sheriff', 'state', 'fbi', 'dea', 'ranger'
    },
    
    -- Medical Departments
    MedicalJobs = {
        'ambulance', 'ems', 'doctor', 'nurse', 'paramedic'
    },
    
    -- Emergency Services (can access both police and medical features)
    EmergencyJobs = {
        'dispatch', 'control'
    }
}

-- Job Grade Configuration (for display purposes only)
Config.JobGrades = {
    ['police'] = {
        [0] = {name = 'Recruit', abbreviation = 'Rct'},
        [1] = {name = 'Officer', abbreviation = 'Ofc'},
        [2] = {name = 'Senior Officer', abbreviation = 'SOfc'},
        [3] = {name = 'Corporal', abbreviation = 'Cpl'},
        [4] = {name = 'Sergeant', abbreviation = 'Sgt'},
        [5] = {name = 'Lieutenant', abbreviation = 'Lt'},
        [6] = {name = 'Captain', abbreviation = 'Cpt'},
        [7] = {name = 'Deputy Chief', abbreviation = 'DChf'},
        [8] = {name = 'Chief', abbreviation = 'Chf'},
        [9] = {name = 'Commissioner', abbreviation = 'Com'},
        [10] = {name = 'Deputy Commissioner', abbreviation = 'DCom'},
        [11] = {name = 'Assistant Commissioner', abbreviation = 'ACom'},
        [12] = {name = 'Superintendent', abbreviation = 'Sup'},
        [13] = {name = 'Deputy Superintendent', abbreviation = 'DSup'},
        [14] = {name = 'Assistant Superintendent', abbreviation = 'ASup'},
        [15] = {name = 'Inspector', abbreviation = 'Insp'},
        [16] = {name = 'Deputy Inspector', abbreviation = 'DInsp'},
        [17] = {name = 'Assistant Inspector', abbreviation = 'AInsp'},
        [18] = {name = 'Commander', abbreviation = 'Cmdr'},
        [19] = {name = 'Deputy Commander', abbreviation = 'DCmdr'},
        [20] = {name = 'Assistant Commander', abbreviation = 'ACmdr'}
    },
    
    ['ambulance'] = {
        [0] = {name = 'Trainee', abbreviation = 'Trn'},
        [1] = {name = 'EMT', abbreviation = 'EMT'},
        [2] = {name = 'Paramedic', abbreviation = 'PM'},
        [3] = {name = 'Senior Paramedic', abbreviation = 'SPM'},
        [4] = {name = 'Supervisor', abbreviation = 'Sup'},
        [5] = {name = 'Lieutenant', abbreviation = 'Lt'},
        [6] = {name = 'Captain', abbreviation = 'Cpt'},
        [7] = {name = 'Deputy Chief', abbreviation = 'DChf'},
        [8] = {name = 'Chief', abbreviation = 'Chf'},
        [9] = {name = 'Medical Director', abbreviation = 'MD'}
    }
}

-- Simplified permissions based on job type
Config.Permissions = {
    Police = {
        'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 
        'create_warrants', 'view_custody', 'manage_custody', 'view_dispatch',
        'view_reports', 'create_reports', 'edit_reports'
    },
    Medical = {
        'view_people', 'view_medical', 'create_medical_incidents', 
        'manage_medical_records', 'view_custody', 'create_medical_reports'
    },
    Emergency = {
        'view_people', 'view_vehicles', 'view_incidents', 'view_dispatch',
        'create_dispatch', 'view_custody'
    },
    Admin = {
        'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 
        'create_warrants', 'view_custody', 'manage_custody', 'view_dispatch',
        'view_medical', 'create_medical_incidents', 'manage_medical_records',
        'view_reports', 'create_reports', 'edit_reports', 'admin_access'
    }
}

-- Jail Configuration
Config.Jail = {
    Enabled = true,
    BaseTimePerCharge = 300, -- 5 minutes per charge in seconds
    GuiltyPleaReduction = 0.25, -- 25% reduction for guilty plea
    MaxSentence = 3600, -- 1 hour maximum in seconds
    DefaultLocation = vector3(459.5, -994.0, 24.9), -- Default jail location
    Cells = {
        {id = 1, label = "Cell 1", coords = vector3(460.0, -994.0, 24.9)},
        {id = 2, label = "Cell 2", coords = vector3(457.0, -994.0, 24.9)},
        {id = 3, label = "Cell 3", coords = vector3(454.0, -994.0, 24.9)},
        {id = 4, label = "Cell 4", coords = vector3(450.0, -994.0, 24.9)},
        {id = 5, label = "Cell 5", coords = vector3(247.0, -1072.0, 29.3)},
        {id = 6, label = "Cell 6", coords = vector3(250.0, -1072.0, 29.3)},
        {id = 7, label = "Cell 7", coords = vector3(253.0, -1072.0, 29.3)},
        {id = 8, label = "Cell 8", coords = vector3(256.0, -1072.0, 29.3)}
    }
}

-- Charge Categories for Jail Time Calculation
Config.ChargeCategories = {
    Minor = {'T001', 'T005', 'P001', 'P002'}, -- Speeding minor, Illegal parking, etc.
    Moderate = {'T002', 'T004', 'P003', 'P004'}, -- Speeding major, Running red light, etc.
    Serious = {'T003', 'T006', 'T007', 'C001'}, -- Reckless driving, No insurance, Theft, etc.
    Major = {'C002', 'C003', 'C004', 'T008'}, -- Assault, Drug possession, Weapons, DUI
    Severe = {'C005', 'C006'} -- Robbery, Murder
}

-- Time multipliers for charge categories
Config.TimeMultipliers = {
    Minor = 1.0,      -- Base time
    Moderate = 1.5,   -- 1.5x base time
    Serious = 2.0,    -- 2x base time
    Major = 3.0,      -- 3x base time
    Severe = 5.0      -- 5x base time
}

-- Discord Webhooks
Config.Webhooks = {
    fines = '',
    incidents = '',
    warrants = '',
    custody = '',
    medical = '',
    jail = '',
    system = ''
}

-- Google Sheets Integration
Config.GoogleSheets = {
    enabled = false,
    webhook_url = ''
}

-- Banking Configuration
Config.Banking = {
    account_type = 'bank', -- 'bank' or 'cash'
    fine_account = 'government',
    jail_account = 'government'
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
    },
    jail = {
        sprite = 188,
        color = 49,
        scale = 0.9,
        label = 'Jail'
    },
    custody = {
        sprite = 189,
        color = 1,
        scale = 0.8,
        label = 'In Custody'
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
    },
    {
        coords = vector3(247.0, -1072.0, 29.3),
        label = "Courthouse"
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
        'update_vehicle',
        'jail_sentence',
        'release_jail'
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
    },
    ['sheriff'] = {
        primary_color = "#8b4513",
        secondary_color = "#a0522d",
        accent_color = "#cd853f",
        text_color = "#ffffff",
        background_color = "#2f1b14"
    }
}

-- System Settings
Config.System = {
    Debug = false,
    Version = "2.0.0",
    UpdateCheck = true,
    AutoBackup = true,
    Performance = {
        MaxSearchResults = 100,
        CacheTimeout = 300, -- 5 minutes
        QueryTimeout = 30   -- 30 seconds
    }
}