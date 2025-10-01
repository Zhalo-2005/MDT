-- Z-MDT Enhanced Configuration - Purple/Blue Theme Edition
Config = {}

-- Core Settings
Config.ResourceName = 'Z-MDT'
Config.Debug = false

-- UI Configuration
Config.UI = {
    -- Theme Options
    themes = {
        ['purple-blue'] = {
            primary = '#6B46C1',
            secondary = '#3B82F6',
            accent = '#8B5CF6',
            background = '#0F0F23',
            text = '#FFFFFF',
            card = 'rgba(30, 30, 60, 0.7)'
        },
        ['dark-red'] = {
            primary = '#DC2626',
            secondary = '#7C2D12',
            accent = '#EF4444',
            background = '#18181B',
            text = '#FFFFFF',
            card = 'rgba(30, 30, 30, 0.7)'
        },
        ['ocean'] = {
            primary = '#0891B2',
            secondary = '#0EA5E9',
            accent = '#06B6D4',
            background = '#0C4A6E',
            text = '#FFFFFF',
            card = 'rgba(20, 40, 60, 0.7)'
        }
    },
    
    -- Default theme
    defaultTheme = 'purple-blue',
    
    -- Animation settings
    animations = {
        enabled = true,
        duration = 300,
        easing = 'ease-out'
    },
    
    -- Responsive breakpoints
    responsive = {
        mobile = 768,
        tablet = 1024,
        desktop = 1440
    }
}

-- Database Configuration
Config.Database = {
    -- Table names
    tables = {
        incidents = 'zmdt_incidents',
        fines = 'zmdt_fines',
        custody = 'zmdt_custody',
        vehicles = 'zmdt_vehicles',
        citizens = 'zmdt_citizens'
    },
    
    -- Default data limits
    limits = {
        incidents = 50,
        fines = 100,
        custody = 25,
        search = 25
    }
}

-- Job Configuration
Config.Jobs = {
    police = {
        name = 'Police Department',
        departments = {'police', 'sheriff', 'state', 'fbi', 'dea'},
        permissions = {
            'view_people', 'view_vehicles', 'create_incidents', 'issue_fines',
            'create_warrants', 'view_custody', 'manage_custody', 'view_dispatch'
        },
        color = '#2563EB'
    },
    
    ambulance = {
        name = 'Medical Services',
        departments = {'ambulance', 'ems', 'doctor'},
        permissions = {
            'view_people', 'view_medical', 'create_medical_incidents',
            'manage_medical_records', 'view_custody'
        },
        color = '#059669'
    }
}

-- Jail Configuration
Config.Jail = {
    -- Base time per charge (seconds)
    baseTimePerCharge = 300, -- 5 minutes
    
    -- Plea reduction percentage
    guiltyPleaReduction = 0.25, -- 25%
    
    -- Maximum sentence (seconds)
    maxSentence = 7200, -- 2 hours
    
    -- Available cells
    cells = {
        {id = "A1", x = 459.0, y = -994.0, z = 24.0, capacity = 1},
        {id = "A2", x = 459.0, y = -997.0, z = 24.0, capacity = 1},
        {id = "A3", x = 459.0, y = -1000.0, z = 24.0, capacity = 1},
        {id = "A4", x = 459.0, y = -1003.0, z = 24.0, capacity = 1},
        {id = "B1", x = 463.0, y = -994.0, z = 24.0, capacity = 1},
        {id = "B2", x = 463.0, y = -997.0, z = 24.0, capacity = 1},
        {id = "B3", x = 463.0, y = -1000.0, z = 24.0, capacity = 1},
        {id = "B4", x = 463.0, y = -1003.0, z = 24.0, capacity = 1}
    }
}

-- Fine Categories
Config.FineCategories = {
    traffic = {
        name = 'Traffic Violations',
        maxAmount = 5000,
        charges = {
            speeding = {amount = 500, description = "Speeding violation"},
            reckless = {amount = 2000, description = "Reckless driving"},
            no_license = {amount = 1500, description = "Driving without license"}
        }
    },
    
    criminal = {
        name = 'Criminal Offenses',
        maxAmount = 50000,
        charges = {
            assault = {amount = 10000, description = "Assault"},
            theft = {amount = 5000, description = "Theft"},
            robbery = {amount = 25000, description = "Robbery"}
        }
    },
    
    civil = {
        name = 'Civil Infractions',
        maxAmount = 10000,
        charges = {
            disorderly = {amount = 2000, description = "Disorderly conduct"},
            trespassing = {amount = 3000, description = "Trespassing"},
            vandalism = {amount = 5000, description = "Vandalism"}
        }
    }
}

-- Incident Priorities
Config.IncidentPriorities = {
    low = {color = '#10B981', responseTime = 30},
    medium = {color = '#F59E0B', responseTime = 15},
    high = {color = '#EF4444', responseTime = 5},
    critical = {color = '#DC2626', responseTime = 1}
}

-- Webhooks (Optional)
Config.Webhooks = {
    enabled = false,
    url = "",
    events = {
        incident_created = true,
        fine_issued = true,
        custody_created = true,
        person_searched = false
    }
}

-- Google Sheets Integration (Optional)
Config.GoogleSheets = {
    enabled = false,
    webhook_url = "",
    spreadsheet_id = ""
}

-- Notification Settings
Config.Notifications = {
    enabled = true,
    types = {
        success = {duration = 3000, sound = true},
        error = {duration = 5000, sound = true},
        info = {duration = 4000, sound = false}
    }
}

-- UI Customization
Config.UI = Config.UI or {}
Config.UI.custom = {
    -- Enable custom branding
    branding = {
        enabled = true,
        logo = "🛡️",
        title = "Z-MDT System",
        subtitle = "Purple/Blue Edition"
    },
    
    -- Dashboard widgets
    widgets = {
        stats = {enabled = true, refresh = 30},
        chart = {enabled = true, type = "activity"},
        quick_actions = {enabled = true}
    },
    
    -- Search enhancements
    search = {
        fuzzy = true,
        autocomplete = true,
        suggestions = true,
        history = true
    },
    
    -- Form enhancements
    forms = {
        validation = true,
        auto_save = true,
        templates = true,
        preview = true
    }
}

-- Tablet item settings
Config.TabletItem = 'zmdt_tablet'
Config.MedicalTabletItem = 'zmdt_medical_tablet'

-- Integration settings
Config.Integrations = {
    Inventory = 'qb-inventory', -- 'qb-inventory' or 'ox_inventory'
    Roster = 'none', -- 'fiveroster' or 'none'
    Ambulance = 'none' -- 'wasabi_ambulance' or 'none'
}

-- Medical flags
Config.MedicalFlags = {
    'Allergic to Penicillin',
    'Diabetic',
    'Epileptic',
    'Heart Condition',
    'Asthma',
    'Pregnancy'
}

-- Charges configuration
Config.Charges = {
    -- Minor offenses
    ['jaywalking'] = {baseTime = 300, multiplier = 1, category = 'minor'},
    ['littering'] = {baseTime = 300, multiplier = 1, category = 'minor'},
    
    -- Moderate offenses
    ['speeding'] = {baseTime = 600, multiplier = 1.5, category = 'moderate'},
    ['reckless_driving'] = {baseTime = 900, multiplier = 1.5, category = 'moderate'},
    
    -- Serious offenses
    ['assault'] = {baseTime = 1800, multiplier = 2, category = 'serious'},
    ['theft'] = {baseTime = 2400, multiplier = 2, category = 'serious'},
    
    -- Major offenses
    ['robbery'] = {baseTime = 3600, multiplier = 3, category = 'major'},
    ['burglary'] = {baseTime = 3600, multiplier = 3, category = 'major'},
    
    -- Severe offenses
    ['armed_robbery'] = {baseTime = 6000, multiplier = 5, category = 'severe'},
    ['murder'] = {baseTime = 7200, multiplier = 5, category = 'severe'}
}

-- Blip settings
Config.Blips = {
    fine_payment = {
        sprite = 408,
        color = 3,
        scale = 0.8,
        label = 'Fine Payment Location'
    },
    incident = {
        sprite = 161,
        color = 1,
        scale = 1.0,
        label = 'Active Incident'
    }
}

-- Fine payment locations
Config.FinePaymentLocations = {
    {
        name = 'Police Station',
        coords = {x = 441.0, y = -981.0, z = 30.0}
    },
    {
        name = 'City Hall',
        coords = {x = 240.0, y = -1379.0, z = 33.0}
    }
}

-- Webhooks (Optional)
Config.Webhooks = {
    enabled = false,
    url = "",
    fines = ""
}

-- Google Sheets integration
Config.GoogleSheets = {
    enabled = false,
    webhook_url = "",
    spreadsheet_id = ""
}

-- Return configuration
return Config