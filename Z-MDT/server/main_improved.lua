local QBCore = exports['qb-core']:GetCoreObject()

-- Database helper function to handle both sync and async queries
local function executeQuery(query, params, callback)
    if callback then
        exports.oxmysql:execute(query, params, callback)
    else
        local result = exports.oxmysql:execute_sync(query, params)
        return result
    end
end

-- Database helper for insert operations
local function executeInsert(query, params, callback)
    if callback then
        exports.oxmysql:insert(query, params, callback)
    else
        local result = exports.oxmysql:insert_sync(query, params)
        return result
    end
end

-- Database helper for scalar queries
local function executeScalar(query, params, callback)
    if callback then
        exports.oxmysql:scalar(query, params, callback)
    else
        local result = exports.oxmysql:scalar_sync(query, params)
        return result
    end
end

-- Get player data helper
local function getPlayerData(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    return {
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        job = Player.PlayerData.job.name,
        grade = Player.PlayerData.job.grade.level
    }
end

-- Check MDT access based on job type (PD vs Ambulance)
local function hasMDTAccess(job)
    if not job then return false end
    
    -- Simplified job detection - just check if it's police/ambulance
    local policeJobs = {'police', 'sheriff', 'state', 'fbi', 'dea'}
    local medicalJobs = {'ambulance', 'ems', 'doctor'}
    
    for _, policeJob in ipairs(policeJobs) do
        if job:lower() == policeJob then
            return 'police'
        end
    end
    
    for _, medicalJob in ipairs(medicalJobs) do
        if job:lower() == medicalJob then
            return 'ambulance'
        end
    end
    
    return false
end

-- NUI Callback: Get Dashboard Statistics
RegisterNUICallback('getDashboardStats', function(data, cb)
    local stats = {
        citizens = 0,
        vehicles = 0,
        incidents = 0,
        warrants = 0,
        activity = {}
    }
    
    -- Get total citizens from players table
    local citizens = executeQuery('SELECT COUNT(*) as count FROM players', {})
    stats.citizens = citizens and citizens[1] and citizens[1].count or 0
    
    -- Get total vehicles
    local vehicles = executeQuery('SELECT COUNT(*) as count FROM player_vehicles', {})
    stats.vehicles = vehicles and vehicles[1] and vehicles[1].count or 0
    
    -- Get active incidents
    local incidents = executeQuery('SELECT COUNT(*) as count FROM zmdt_incidents WHERE status = ?', {'active'})
    stats.incidents = incidents and incidents[1] and incidents[1].count or 0
    
    -- Get active warrants
    local warrants = executeQuery('SELECT COUNT(*) as count FROM zmdt_warrants WHERE status = ?', {'active'})
    stats.warrants = warrants and warrants[1] and warrants[1].count or 0
    
    -- Get recent activity
    local activity = executeQuery('SELECT * FROM zmdt_audit_logs ORDER BY created_at DESC LIMIT 5', {})
    if activity then
        for _, v in ipairs(activity) do
            table.insert(stats.activity, { 
                time = v.created_at, 
                text = v.action .. ' by ' .. v.user_name,
                details = v.details
            })
        end
    end
    
    cb(stats)
end)

-- NUI Callback: Search Person
RegisterNUICallback('searchPerson', function(data, cb)
    local query = data.query
    
    -- Search in zmdt_citizens first
    local result = executeQuery('SELECT * FROM zmdt_citizens WHERE citizenid = ? OR CONCAT(firstname, " ", lastname) LIKE ?', {
        query, '%' .. query .. '%'
    })
    
    if result and result[1] then
        local person = result[1]
        
        -- Get additional data
        local fines = executeQuery('SELECT * FROM zmdt_fines WHERE citizenid = ? ORDER BY created_at DESC', {person.citizenid})
        local warrants = executeQuery('SELECT * FROM zmdt_warrants WHERE citizenid = ? AND status = ?', {person.citizenid, 'active'})
        local incidents = executeQuery('SELECT * FROM zmdt_incidents WHERE involved_citizens LIKE ? ORDER BY created_at DESC LIMIT 10', {'%' .. person.citizenid .. '%'})
        
        person.fines = fines or {}
        person.warrants = warrants or {}
        person.incidents = incidents or {}
        
        cb({success = true, data = person})
    else
        -- Try to get from players table and create citizen record
        local playerResult = executeQuery('SELECT * FROM players WHERE citizenid = ?', {query})
        if playerResult and playerResult[1] then
            local playerData = json.decode(playerResult[1].charinfo)
            if playerData then
                -- Create citizen record
                executeInsert('INSERT INTO zmdt_citizens (citizenid, firstname, lastname, dob, phone) VALUES (?, ?, ?, ?, ?)', {
                    query,
                    playerData.firstname,
                    playerData.lastname,
                    playerData.birthdate,
                    playerData.phone
                })
                
                cb({success = true, data = {
                    citizenid = query,
                    firstname = playerData.firstname,
                    lastname = playerData.lastname,
                    dob = playerData.birthdate,
                    phone = playerData.phone,
                    penalty_points = 0,
                    fines = {},
                    warrants = {},
                    incidents = {}
                }})
            else
                cb({success = false, message = 'Failed to decode player data'})
            end
        else
            cb({success = false, message = 'Person not found'})
        end
    end
end)

-- NUI Callback: Search Vehicle
RegisterNUICallback('searchVehicle', function(data, cb)
    local query = data.query:upper() -- Ensure uppercase for license plates
    
    -- Search in player_vehicles first
    local result = executeQuery('SELECT * FROM player_vehicles WHERE plate = ?', {query})
    
    if result and result[1] then
        local vehicle = result[1]
        
        -- Get owner name from players table
        local owner = executeQuery('SELECT charinfo FROM players WHERE citizenid = ?', {vehicle.citizenid})
        if owner and owner[1] then
            local charinfo = json.decode(owner[1].charinfo)
            vehicle.owner_name = charinfo and (charinfo.firstname .. ' ' .. charinfo.lastname) or 'Unknown'
        else
            vehicle.owner_name = 'Unknown'
        end
        
        -- Get incidents involving this vehicle
        local incidents = executeQuery('SELECT * FROM zmdt_incidents WHERE involved_vehicles LIKE ? ORDER BY created_at DESC LIMIT 10', {'%' .. query .. '%'})
        vehicle.incidents = incidents or {}
        
        cb({success = true, data = vehicle})
    else
        -- Try zmdt_vehicles table
        local zmdtResult = executeQuery('SELECT * FROM zmdt_vehicles WHERE plate = ?', {query})
        if zmdtResult and zmdtResult[1] then
            local vehicle = zmdtResult[1]
            
            -- Get incidents involving this vehicle
            local incidents = executeQuery('SELECT * FROM zmdt_incidents WHERE involved_vehicles LIKE ? ORDER BY created_at DESC LIMIT 10', {'%' .. query .. '%'})
            vehicle.incidents = incidents or {}
            
            cb({success = true, data = vehicle})
        else
            cb({success = false, message = 'Vehicle not found'})
        end
    end
end)

-- NUI Callback: Create Incident
RegisterNUICallback('createIncident', function(data, cb)
    local src = source
    local Player = getPlayerData(src)
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return
    end
    
    -- Validate required fields
    if not data.title or not data.description or not data.location then
        cb({success = false, message = 'Missing required fields'})
        return
    end
    
    local incidentId = 'INC-' .. math.random(100000, 999999)
    
    -- Get player coordinates if not provided
    local coords = data.coords or vector3(0, 0, 0)
    if type(coords) == 'table' then
        coords = json.encode(coords)
    end
    
    local success = executeInsert('INSERT INTO zmdt_incidents (incident_id, title, description, location, coords, officer_id, officer_name, priority, type, involved_citizens, involved_vehicles) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        incidentId,
        data.title,
        data.description,
        data.location,
        coords,
        Player.citizenid,
        Player.name,
        data.priority or 'medium',
        data.type or 'police',
        json.encode(data.involved_citizens or {}),
        json.encode(data.involved_vehicles or {})
    })
    
    if success then
        -- Send webhook
        SendWebhook('incidents', {
            title = 'New Incident Created',
            description = data.title,
            officer = Player.name,
            incident_id = incidentId,
            location = data.location
        })
        
        -- Log action
        LogAction(src, 'CREATE_INCIDENT', 'Created incident: ' .. incidentId)
        
        cb({success = true, message = 'Incident created successfully', incident_id = incidentId})
    else
        cb({success = false, message = 'Failed to create incident'})
    end
end)

-- NUI Callback: Get MDT Data
RegisterNUICallback('getMDTData', function(data, cb)
    local src = source
    local Player = getPlayerData(src)
    if not Player then 
        cb({})
        return
    end
    
    -- Determine user role based on job
    local userRole = hasMDTAccess(Player.job)
    
    local data = {
        player = {
            name = Player.name,
            job = Player.job,
            grade = Player.grade,
            badge = Player.grade,
            role = userRole
        },
        charges = Config.Charges,
        permissions = GetPlayerPermissions(Player.job, Player.grade)
    }
    
    cb(data)
end)

-- Get player permissions based on job
function GetPlayerPermissions(job, grade)
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

-- Export functions
exports('hasMDTAccess', hasMDTAccess)
exports('getPlayerData', getPlayerData)
exports('executeQuery', executeQuery)