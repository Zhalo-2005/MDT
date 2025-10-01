-- Z-MDT Configuration
Config = {}

-- Core Settings
Config.Debug = false
Config.DefaultKey = 'F6'
Config.UseTabletItem = true
Config.RestrictToVehicle = false

-- Job Configuration (Simplified - Police or Ambulance only)
Config.AuthorizedJobs = {
    ['police'] = {
        label = 'Police Department',
        grades = {0, 1, 2, 3, 4}, -- All grades have access
        actions = {
            'view_mdt',
            'create_reports',
            'issue_fines',
            'view_fines',
            'create_bolos',
            'jail_players',
            'view_jail'
        }
    },
    ['ambulance'] = {
        label = 'Emergency Medical Services',
        grades = {0, 1, 2, 3, 4}, -- All grades have access
        actions = {
            'view_mdt',
            'create_reports',
            'view_incidents'
        }
    }
}

-- Banking Configuration
Config.Banking = {
    account_type = 'bank', -- 'cash' or 'bank'
    fine_account = 'police' -- Account name for fine payments
}

-- Fine Payment Locations
Config.FinePaymentLocations = {
    {
        name = "Police Station",
        coords = vector3(441.8, -982.1, 30.7),
        blip = true
    },
    {
        name = "City Hall",
        coords = vector3(-544.7, -204.3, 38.2),
        blip = true
    },
    {
        name = "Bank",
        coords = vector3(149.5, -1041.2, 29.4),
        blip = true
    }
}

-- Jail Configuration
Config.Jail = {
    enabled = true,
    max_sentence_days = 365,
    base_jail_time = 5, -- minutes
    plea_reduction = 0.25, -- 25% reduction for guilty plea
    
    -- Jail locations
    locations = {
        {
            name = "Mission Row PD",
            coords = vector3(459.5, -994.7, 24.9),
            cells = 6
        },
        {
            name = "Sandy Shores PD",
            coords = vector3(1855.6, 3683.2, 34.3),
            cells = 4
        }
    },
    
    -- Charge categories and multipliers
    charges = {
        minor = { multiplier = 1.0, max_time = 15 },
        moderate = { multiplier = 1.5, max_time = 30 },
        serious = { multiplier = 2.0, max_time = 60 },
        major = { multiplier = 3.0, max_time = 120 },
        severe = { multiplier = 5.0, max_time = 240 }
    }
}

-- Webhook Configuration
Config.Webhooks = {
    fines = '',
    incidents = '',
    bolos = '',
    jail = ''
}

-- Integration Settings
Config.Integrations = {
    Banking = 'qb-management', -- Options: 'okokBanking', 'qb-banking', 'codm-banking', 'qb-management'
    Dispatch = 'ps-dispatch', -- Options: 'ps-dispatch', 'cd-dispatch'
    Inventory = 'qb-inventory', -- Options: 'qb-inventory', 'ox_inventory'
    Target = 'qb-target', -- Options: 'qb-target', 'ox_target'
    Notifications = 'qb-core' -- Options: 'qb-core', 'okokNotify', 'mythic_notify'
}

-- Google Sheets Integration
Config.GoogleSheets = {
    enabled = false,
    webhook_url = '',
    spreadsheet_id = ''
}

-- UI Themes
Config.Themes = {
    {
        name = "Purple Blue",
        primary = "#6366f1",
        secondary = "#3b82f6",
        accent = "#8b5cf6",
        background = "#0f172a",
        surface = "#1e293b"
    },
    {
        name = "Dark Red",
        primary = "#dc2626",
        secondary = "#991b1b",
        accent = "#f59e0b",
        background = "#111827",
        surface = "#374151"
    },
    {
        name = "Ocean Blue",
        primary = "#0891b2",
        secondary = "#0e7490",
        accent = "#06b6d4",
        background = "#083344",
        surface = "#164e63"
    }
}

-- Feature Flags
Config.Features = {
    fingerprint_scanner = true,
    camera_integration = true,
    voice_recording = true,
    evidence_upload = true,
    real_time_tracking = true,
    automatic_backup = true,
    dark_mode = true,
    multi_language = false
}

-- Performance Settings
Config.Performance = {
    refresh_interval = 30000, -- 30 seconds
    max_search_results = 100,
    cache_duration = 300, -- 5 minutes
    auto_save_interval = 60000 -- 1 minute
}

-- Debug Commands (only active when Config.Debug = true)
if Config.Debug then
    RegisterCommand('zmdt:debug', function()
        print("Z-MDT Debug Mode Active")
        print("Authorized Jobs:", json.encode(Config.AuthorizedJobs))
        print("Tablet Item:", Config.UseTabletItem)
        print("Restrict to Vehicle:", Config.RestrictToVehicle)
    end, false)
end

-- Helper function to check if job is allowed for specific action
function IsJobAllowed(job, action)
    if not Config.AuthorizedJobs[job] then return false end
    
    local jobConfig = Config.AuthorizedJobs[job]
    if jobConfig.actions and type(jobConfig.actions) == 'table' then
        for _, allowedAction in pairs(jobConfig.actions) do
            if allowedAction == action then
                return true
            end
        end
    end
    
    -- Default allow if no specific actions defined
    return true
end

-- Logging function
function LogAction(source, action, details)
    if Config.Debug then
        print(string.format("[Z-MDT] %s - %s: %s", GetPlayerName(source), action, details))
    end
    
    -- Add to database log if needed
    if Config.Webhooks.logs ~= '' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local logData = {
                action = action,
                player = Player.PlayerData.citizenid,
                player_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                details = details,
                timestamp = os.date("%Y-%m-%d %H:%M:%S")
            }
            
            PerformHttpRequest(Config.Webhooks.logs, function(err, text, headers) end, 'POST', json.encode(logData), {['Content-Type'] = 'application/json'})
        end
    end
end