-- Enhanced Z-MDT Configuration
-- This configuration includes all new features and improvements

Config = {}

-- Framework Detection
Config.Framework = 'qb-core' -- 'qb-core' or 'qbox'

-- Version and Update Settings
Config.Version = '2.0.0'
Config.AutoUpdate = true
Config.UpdateCheckInterval = 3600 -- 1 hour

-- Performance Settings
Config.Performance = {
    MaxDatabaseQueriesPerSecond = 100,
    CacheExpirationTime = 300, -- 5 minutes
    RealTimeUpdateInterval = 1000, -- 1 second
    MaxConcurrentRequests = 50,
    EnableQueryOptimization = true,
    EnableCaching = true,
    CachePlayerData = true,
    CacheVehicleData = true,
    CacheTime = 300 -- 5 minutes
}

-- Integrations (Enhanced)
Config.Integrations = {
    Police = 'wasabi_police',
    Ambulance = 'wasabi_ambulance',
    Banking = 'codm-banking', -- 'okokBanking', 'qb-banking', 'codm-banking', 'qb-management'
    Dispatch = 'custom', -- 'rcore', 'ps-dispatch', 'custom'
    Inventory = 'qb-inventory',
    Roster = 'fiveroster',
    -- New integrations
    Dealership = 'jg-dealership', -- JG-Dealership integration
    Discord = {
        enabled = true,
        bot_name = 'Z-MDT Bot',
        avatar_url = '',
        footer_text = 'Z-MDT System'
    },
    GoogleServices = {
        enabled = false,
        api_key = '',
        sheets_integration = false,
        maps_integration = false
    },
    PhotoUpload = {
        service = 'imgur', -- 'imgur', 'discord', 'custom'
        api_key = '',
        max_file_size = 10485760, -- 10MB
        allowed_formats = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
    }
}

-- Tablet Item
Config.TabletItem = 'zmdt_tablet'

-- Jobs with MDT Access (Enhanced with auto-rank detection)
Config.AuthorizedJobs = {
    ['police'] = {
        auto_detect_ranks = true, -- Auto-detect ranks from qb-core/shared/jobs.lua
        permissions = {
            'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 
            'create_warrants', 'view_custody', 'manage_custody', 'view_audit_logs',
            'manage_evidence', 'access_boss_menu', 'view_dispatch', 'manage_dispatch',
            'view_reports', 'create_reports', 'edit_reports', 'delete_reports',
            'view_statistics', 'manage_department', 'access_armory', 'manage_fleet'
        },
        min_grade_for_boss = 3, -- Minimum grade for boss actions
        min_grade_for_high_command = 4 -- Minimum grade for high command actions
    },
    ['ambulance'] = {
        auto_detect_ranks = true,
        permissions = {
            'view_people', 'view_medical', 'create_medical_incidents', 
            'manage_medical_records', 'view_dispatch', 'access_medical_supplies'
        },
        min_grade_for_boss = 3
    },
    ['sheriff'] = {
        auto_detect_ranks = true,
        permissions = {
            'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 
            'create_warrants', 'view_custody', 'manage_custody', 'view_audit_logs',
            'manage_evidence', 'access_boss_menu', 'view_dispatch', 'manage_dispatch'
        },
        min_grade_for_boss = 3,
        min_grade_for_high_command = 4
    },
    ['fib'] = {
        auto_detect_ranks = true,
        permissions = {
            'view_people', 'view_vehicles', 'create_incidents', 'view_audit_logs',
            'manage_evidence', 'access_federal_databases', 'create_federal_warrants'
        },
        min_grade_for_boss = 3
    }
}

-- Government Tax Configuration
Config.GovernmentTax = {
    enabled = true,
    tax_rate = 0.10, -- 10% tax on all fines
    government_account = 'GOVERNMENT_ACCOUNT',
    pd_account = 'POLICE_ACCOUNT',
    tax_distribution = {
        government = 0.10, -- 10% to government
        police = 0.60,     -- 60% to police department
        state = 0.20,      -- 20% to state
        city = 0.10        -- 10% to city
    }
}

-- Fine System Configuration
Config.FineSystem = {
    max_fine_amount = 100000,
    default_due_days = 7,
    late_fee_percentage = 0.05, -- 5% late fee
    enable_payment_plans = true,
    max_installments = 12,
    min_installment_amount = 100,
    enable_warrants_for_unpaid = true,
    warrant_threshold_days = 14,
    payment_locations = {
        {
            coords = vector3(240.06, -1074.73, 29.29),
            label = "Courthouse",
            blip = true,
            payment_fee = 0
        },
        {
            coords = vector3(442.0, -981.0, 30.7),
            label = "LSPD Station",
            blip = true,
            payment_fee = 50
        },
        {
            coords = vector3(1853.0, 3689.0, 34.3),
            label = "Sandy Shores Sheriff",
            blip = true,
            payment_fee = 25
        },
        {
            coords = vector3(-447.0, 6013.0, 31.7),
            label = "Paleto Bay Sheriff",
            blip = true,
            payment_fee = 25
        }
    }
}

-- Real-time Updates Configuration
Config.RealTimeUpdates = {
    enabled = true,
    update_interval = 1000, -- 1 second
    player_position_updates = true,
    unit_status_updates = true,
    dispatch_updates = true,
    incident_updates = true,
    custody_updates = true,
    max_update_frequency = 100, -- Max updates per second
    batch_updates = true,
    compression_enabled = true
}

-- Discord Webhooks (Enhanced)
Config.Webhooks = {
    fines = '',
    incidents = '',
    warrants = '',
    custody = '',
    medical = '',
    dispatch = '',
    evidence = '',
    audit_logs = '',
    boss_actions = '',
    department_finances = '',
    system_errors = '',
    player_actions = '',
    vehicle_actions = ''
}

-- Discord Bot Configuration
Config.DiscordBot = {
    enabled = true,
    bot_token = '',
    guild_id = '',
    log_channel_id = '',
    fine_channel_id = '',
    incident_channel_id = '',
    warrant_channel_id = '',
    custody_channel_id = '',
    evidence_channel_id = '',
    boss_channel_id = '',
    embed_colors = {
        info = 3447003,
        success = 3066993,
        warning = 16776960,
        error = 15158332,
        critical = 10038562
    }
}

-- Evidence System Configuration
Config.EvidenceSystem = {
    enabled = true,
    storage_locations = {
        {
            name = "LSPD Evidence Locker",
            coords = vector3(441.0, -983.0, 30.7),
            access_level = 2,
            max_capacity = 1000,
            categories = {'physical', 'digital', 'drug', 'weapon'}
        },
        {
            name = "Sandy Shores Evidence",
            coords = vector3(1853.0, 3689.0, 34.3),
            access_level = 2,
            max_capacity = 500,
            categories = {'physical', 'digital', 'drug', 'weapon'}
        },
        {
            name = "Paleto Bay Evidence",
            coords = vector3(-447.0, 6013.0, 31.7),
            access_level = 2,
            max_capacity = 500,
            categories = {'physical', 'digital', 'drug', 'weapon'}
        }
    },
    chain_of_custody = {
        enabled = true,
        require_signature = true,
        require_witness = true,
        max_custody_time = 2592000, -- 30 days
        auto_disposition = true
    },
    analysis = {
        enabled = true,
        lab_locations = {
            vector3(441.0, -983.0, 30.7),
            vector3(1853.0, 3689.0, 34.3)
        },
        analysis_time = {
            dna = 86400, -- 24 hours
            fingerprint = 3600, -- 1 hour
            drug = 7200, -- 2 hours
            ballistics = 14400, -- 4 hours
            digital = 28800 -- 8 hours
        }
    }
}

-- Boss Menu Configuration
Config.BossMenu = {
    enabled = true,
    command = 'bossmenu',
    keybind = 'F6',
    locations = {
        {
            coords = vector3(441.0, -983.0, 30.7),
            job = 'police',
            label = "LSPD Boss Menu",
            blip = true
        },
        {
            coords = vector3(1853.0, 3689.0, 34.3),
            job = 'sheriff',
            label = "Sandy Shores Boss Menu",
            blip = true
        },
        {
            coords = vector3(-447.0, 6013.0, 31.7),
            job = 'sheriff',
            label = "Paleto Bay Boss Menu",
            blip = true
        }
    },
    features = {
        employee_management = true,
        salary_management = true,
        budget_management = true,
        fleet_management = true,
        armory_management = true,
        evidence_management = true,
        statistics = true,
        announcements = true,
        duty_roster = true
    }
}

-- Photo and Media Configuration
Config.Media = {
    max_photos_per_incident = 20,
    max_photos_per_person = 10,
    max_photos_per_vehicle = 10,
    max_photo_size = 10485760, -- 10MB
    allowed_photo_formats = {'png', 'jpg', 'jpeg', 'gif', 'webp'},
    max_videos_per_incident = 5,
    max_video_size = 52428800, -- 50MB
    allowed_video_formats = {'mp4', 'avi', 'mov', 'wmv'},
    enable_cloud_storage = false,
    cloud_storage_provider = 'aws', -- 'aws', 'google', 'azure'
    compression_quality = 0.8,
    thumbnail_generation = true
}

-- Medical System Configuration
Config.MedicalSystem = {
    enabled = true,
    medical_flags = {
        {
            id = "allergies",
            label = "Allergies",
            description = "Patient has significant allergies",
            color = "red",
            icon = "fa-exclamation-triangle"
        },
        {
            id = "heart_condition",
            label = "Heart Condition",
            description = "Patient has a heart condition",
            color = "red",
            icon = "fa-heartbeat"
        },
        {
            id = "diabetes",
            label = "Diabetes",
            description = "Patient has diabetes",
            color = "orange",
            icon = "fa-syringe"
        },
        {
            id = "epilepsy",
            label = "Epilepsy",
            description = "Patient has epilepsy",
            color = "orange",
            icon = "fa-brain"
        },
        {
            id = "asthma",
            label = "Asthma",
            description = "Patient has asthma",
            color = "yellow",
            icon = "fa-lungs"
        },
        {
            id = "dnr",
            label = "DNR",
            description = "Do Not Resuscitate order in place",
            color = "purple",
            icon = "fa-ban"
        },
        {
            id = "mental_health",
            label = "Mental Health",
            description = "Patient has mental health conditions",
            color = "blue",
            icon = "fa-brain"
        },
        {
            id = "pregnant",
            label = "Pregnant",
            description = "Patient is pregnant",
            color = "pink",
            icon = "fa-baby"
        }
    }
}

-- Custody System Configuration
Config.CustodySystem = {
    max_custody_time = 43200, -- 12 hours in seconds
    default_custody_time = 1800, -- 30 minutes
    cell_locations = {
        {
            id = 1,
            label = "LSPD Cell 1",
            coords = vector3(460.0, -994.0, 24.9),
            capacity = 1,
            security_level = "medium"
        },
        {
            id = 2,
            label = "LSPD Cell 2",
            coords = vector3(457.0, -994.0, 24.9),
            capacity = 1,
            security_level = "medium"
        },
        {
            id = 3,
            label = "LSPD Cell 3",
            coords = vector3(454.0, -994.0, 24.9),
            capacity = 1,
            security_level = "high"
        },
        {
            id = 4,
            label = "LSPD Cell 4",
            coords = vector3(450.0, -994.0, 24.9),
            capacity = 1,
            security_level = "maximum"
        }
    },
    enable_parole_system = true,
    enable_probation_system = true,
    enable_work_release = true,
    enable_bail_system = true,
    enable_public_defender = true
}

-- Dispatch System Configuration
Config.DispatchSystem = {
    max_active_calls = 50,
    auto_assign_calls = true,
    priority_system = true,
    backup_request_system = true,
    unit_tracking = true,
    gps_integration = true,
    radio_integration = true,
    call_priority_weights = {
        critical = 100,
        high = 75,
        medium = 50,
        low = 25
    },
    response_time_targets = {
        critical = 180, -- 3 minutes
        high = 300,     -- 5 minutes
        medium = 600,   -- 10 minutes
        low = 900       -- 15 minutes
    }
}

-- UI Themes (Enhanced)
Config.UIThemes = {
    ['police'] = {
        primary_color = "#1a3c6e",
        secondary_color = "#2c5ba3",
        accent_color = "#4287f5",
        text_color = "#ffffff",
        background_color = "#0a1e37",
        success_color = "#28a745",
        warning_color = "#ffc107",
        error_color = "#dc3545",
        info_color = "#17a2b8"
    },
    ['ambulance'] = {
        primary_color = "#8b0000",
        secondary_color = "#b22222",
        accent_color = "#ff0000",
        text_color = "#ffffff",
        background_color = "#400000",
        success_color = "#28a745",
        warning_color = "#ffc107",
        error_color = "#dc3545",
        info_color = "#17a2b8"
    },
    ['sheriff'] = {
        primary_color = "#8b4513",
        secondary_color = "#a0522d",
        accent_color = "#d2691e",
        text_color = "#ffffff",
        background_color = "#4b2f20",
        success_color = "#28a745",
        warning_color = "#ffc107",
        error_color = "#dc3545",
        info_color = "#17a2b8"
    },
    ['fib'] = {
        primary_color = "#000080",
        secondary_color = "#0000cd",
        accent_color = "#4169e1",
        text_color = "#ffffff",
        background_color = "#000033",
        success_color = "#28a745",
        warning_color = "#ffc107",
        error_color = "#dc3545",
        info_color = "#17a2b8"
    }
}

-- Audit Log Settings (Enhanced)
Config.AuditLog = {
    enabled = true,
    retention_days = 90, -- Extended to 90 days
    log_actions = {
        'search_person', 'search_vehicle', 'create_incident', 'update_incident',
        'issue_fine', 'create_warrant', 'update_warrant', 'create_custody',
        'release_custody', 'create_medical_record', 'update_medical_record',
        'take_mugshot', 'take_evidence_photo', 'update_person', 'update_vehicle',
        'access_boss_menu', 'manage_employee', 'access_evidence', 'manage_evidence',
        'view_audit_logs', 'access_armory', 'manage_fleet', 'create_dispatch',
        'accept_dispatch', 'close_dispatch', 'payment_processed', 'government_tax_collected'
    },
    log_level = 'info', -- 'debug', 'info', 'warning', 'error'
    max_log_size = 10000, -- Maximum number of logs before rotation
    enable_real_time_monitoring = true,
    suspicious_activity_detection = true
}

-- Mugshot Settings (Enhanced)
Config.Mugshot = {
    coords = vector4(402.91665649414, -996.75970458984, -99.000259399414, 186.22036743164),
    camera_coords = vector4(402.91665649414, -995.75970458984, -98.5, 186.22036743164),
    upload_url = 'https://api.imgur.com/3/image',
    upload_headers = {
        ['Authorization'] = 'Client-ID YOUR_IMGUR_CLIENT_ID'
    },
    max_mugshots_per_person = 5,
    enable_auto_upload = true,
    enable_facial_recognition = false,
    enable_fingerprint_scanner = false
}

-- Security Settings
Config.Security = {
    enable_ip_whitelist = false,
    whitelisted_ips = {},
    enable_rate_limiting = true,
    max_requests_per_minute = 100,
    enable_session_management = true,
    session_timeout = 1800, -- 30 minutes
    require_two_factor = false,
    encryption_enabled = true,
    data_retention_days = 365,
    enable_data_anonymization = false
}

-- Development Settings
Config.Development = {
    debug_mode = false,
    enable_test_data = false,
    log_sql_queries = false,
    enable_performance_monitoring = true,
    enable_error_reporting = true,
    max_error_logs = 1000
}

-- Localization
Config.Locale = 'en'
Config.Languages = {
    ['en'] = {
        -- Add all UI strings here for internationalization
    }
}