-- Z-MDT Server Main (Fixed)
local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize database
CreateThread(function()
    Wait(1000) -- Wait for database connection
    
    -- Create tables if they don't exist
    local queries = {
        [[
            CREATE TABLE IF NOT EXISTS zmdt_incidents (
                id INT AUTO_INCREMENT PRIMARY KEY,
                incident_id VARCHAR(50) UNIQUE,
                title VARCHAR(255),
                description TEXT,
                citizenid VARCHAR(50),
                officer_id VARCHAR(50),
                location VARCHAR(255),
                evidence JSON,
                severity VARCHAR(50),
                status VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]],
        [[
            CREATE TABLE IF NOT EXISTS zmdt_citizens (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50) UNIQUE,
                firstname VARCHAR(50),
                lastname VARCHAR(50),
                dob DATE,
                phone VARCHAR(20),
                address TEXT,
                mugshot VARCHAR(255),
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]],
        [[
            CREATE TABLE IF NOT EXISTS zmdt_vehicles (
                id INT AUTO_INCREMENT PRIMARY KEY,
                plate VARCHAR(20) UNIQUE,
                citizenid VARCHAR(50),
                model VARCHAR(100),
                color VARCHAR(50),
                vin VARCHAR(50),
                insurance VARCHAR(50),
                registration VARCHAR(50),
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]],
        [[
            CREATE TABLE IF NOT EXISTS zmdt_warrants (
                id INT AUTO_INCREMENT PRIMARY KEY,
                warrant_id VARCHAR(50) UNIQUE,
                citizenid VARCHAR(50),
                type VARCHAR(50),
                description TEXT,
                issued_by VARCHAR(50),
                status VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]],
        [[
            CREATE TABLE IF NOT EXISTS zmdt_fines (
                id INT AUTO_INCREMENT PRIMARY KEY,
                fine_id VARCHAR(50) UNIQUE,
                citizenid VARCHAR(50),
                officer_id VARCHAR(50),
                amount INT,
                reason TEXT,
                status VARCHAR(50),
                due_date DATE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]],
        [[
            CREATE TABLE IF NOT EXISTS zmdt_custody (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50),
                officer_id VARCHAR(50),
                cell_id VARCHAR(50),
                charges JSON,
                jail_time INT,
                start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                end_time TIMESTAMP,
                status VARCHAR(50),
                notes TEXT
            )
        ]],
        [[
            CREATE TABLE IF NOT EXISTS zmdt_medical_records (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50),
                incident_type VARCHAR(100),
                description TEXT,
                treatment TEXT,
                medications TEXT,
                allergies TEXT,
                medical_flags JSON,
                created_by VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]]
    }
    
    for _, query in ipairs(queries) do
        MySQL.query(query)
    end
    
    print('^2[Z-MDT] Database tables initialized successfully^0')
end)

-- Helper function to execute queries
function executeQuery(query, params)
    local result = MySQL.query.await(query, params)
    return result
end

-- Helper function to execute inserts
function executeInsert(query, params)
    local result = MySQL.insert.await(query, params)
    return result
end

-- Check if player has MDT access
function hasMDTAccess(job)
    if not job then return false end
    
    local jobName = job:lower()
    
    -- Police jobs
    local policeJobs = {'police', 'sheriff', 'state', 'fbi', 'dea'}
    for _, policeJob in ipairs(policeJobs) do
        if jobName == policeJob then
            return 'police'
        end
    end
    
    -- Medical jobs
    local medicalJobs = {'ambulance', 'ems', 'doctor'}
    for _, medicalJob in ipairs(medicalJobs) do
        if jobName == medicalJob then
            return 'ambulance'
        end
    end
    
    return false
end

-- Get player data
function getPlayerData(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    
    return {
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        job = Player.PlayerData.job.name:lower(),
        grade = Player.PlayerData.job.grade.level
    }
end

-- Get player permissions
function getPlayerPermissions(job, grade)
    local permissions = {}
    local jobType = hasMDTAccess(job)
    
    if jobType == 'police' then
        permissions = {
            'view_people', 'view_vehicles', 'create_incidents', 'issue_fines',
            'create_warrants', 'view_custody', 'manage_custody', 'view_dispatch'
        }
    elseif jobType == 'ambulance' then
        permissions = {
            'view_people', 'view_medical', 'create_medical_incidents',
            'manage_medical_records', 'view_custody'
        }
    end
    
    return permissions
end

-- Server Events
RegisterServerEvent('zmdt:server:getDashboardStats')
AddEventHandler('zmdt:server:getDashboardStats', function()
    local src = source
    local stats = {
        citizens = 0,
        vehicles = 0,
        incidents = 0,
        warrants = 0,
        fines = 0,
        custody = 0
    }
    
    -- Get citizen count
    local citizens = executeQuery('SELECT COUNT(*) as count FROM players')
    if citizens and citizens[1] then
        stats.citizens = citizens[1].count
    end
    
    -- Get vehicle count
    local vehicles = executeQuery('SELECT COUNT(*) as count FROM player_vehicles')
    if vehicles and vehicles[1] then
        stats.vehicles = vehicles[1].count
    end
    
    -- Get incident count
    local incidents = executeQuery('SELECT COUNT(*) as count FROM zmdt_incidents')
    if incidents and incidents[1] then
        stats.incidents = incidents[1].count
    end
    
    -- Get warrant count
    local warrants = executeQuery('SELECT COUNT(*) as count FROM zmdt_warrants WHERE status = ?', {'active'})
    if warrants and warrants[1] then
        stats.warrants = warrants[1].count
    end
    
    -- Get fine count
    local fines = executeQuery('SELECT COUNT(*) as count FROM zmdt_fines')
    if fines and fines[1] then
        stats.fines = fines[1].count
    end
    
    -- Get custody count
    local custody = executeQuery('SELECT COUNT(*) as count FROM zmdt_custody WHERE status = ?', {'active'})
    if custody and custody[1] then
        stats.custody = custody[1].count
    end
    
    TriggerClientEvent('zmdt:client:dashboardStats', src, stats)
end)

RegisterServerEvent('zmdt:server:searchPerson')
AddEventHandler('zmdt:server:searchPerson', function(query)
    local src = source
    
    -- Search in players table
    local result = executeQuery('SELECT * FROM players WHERE citizenid = ? OR CONCAT(firstname, " ", lastname) LIKE ?', {
        query, '%' .. query .. '%'
    })
    
    TriggerClientEvent('zmdt:client:searchResults', src, result or {})
end)

RegisterServerEvent('zmdt:server:searchVehicle')
AddEventHandler('zmdt:server:searchVehicle', function(query)
    local src = source
    local searchQuery = query:upper()
    
    -- Search in player_vehicles
    local result = executeQuery('SELECT * FROM player_vehicles WHERE plate = ?', {searchQuery})
    
    TriggerClientEvent('zmdt:client:vehicleSearchResults', src, result or {})
end)

RegisterServerEvent('zmdt:server:createIncident')
AddEventHandler('zmdt:server:createIncident', function(data)
    local src = source
    local Player = getPlayerData(src)
    if not Player then 
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    -- Ensure required fields
    if not data.title or not data.description then
        TriggerClientEvent('QBCore:Notify', src, 'Missing required fields', 'error')
        return
    end
    
    -- Generate incident ID
    local incidentId = 'INC' .. os.time()
    
    -- Insert incident
    local success = executeInsert([[
        INSERT INTO zmdt_incidents (incident_id, title, description, citizenid, officer_id, location, evidence, severity, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
    ]], {
        incidentId,
        data.title,
        data.description,
        data.citizenid or Player.citizenid,
        Player.citizenid,
        data.location or 'Unknown',
        json.encode(data.evidence or {}),
        data.severity or 'medium',
        'open'
    })
    
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Incident created successfully', 'success')
        TriggerClientEvent('zmdt:client:incidentCreated', src, incidentId)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to create incident', 'error')
    end
end)

RegisterServerEvent('zmdt:server:getMDTData')
AddEventHandler('zmdt:server:getMDTData', function()
    local src = source
    local Player = getPlayerData(src)
    if not Player then 
        TriggerClientEvent('zmdt:client:mdtData', src, {})
        return
    end
    
    local data = {
        player = Player,
        permissions = getPlayerPermissions(Player.job, Player.grade)
    }
    
    TriggerClientEvent('zmdt:client:mdtData', src, data)
end)

-- Export functions
exports('hasMDTAccess', hasMDTAccess)
exports('getPlayerData', getPlayerData)
exports('executeQuery', executeQuery)