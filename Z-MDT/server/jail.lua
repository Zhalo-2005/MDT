-- Z-MDT Jail System (Fixed)
local QBCore = exports['qb-core']:GetCoreObject()

-- Jail Configuration
local JailConfig = {
    BaseTimePerCharge = 300, -- 5 minutes per charge
    GuiltyPleaReduction = 0.25, -- 25% reduction for guilty plea
    MaxSentence = 7200, -- 2 hours max
    Cells = {
        {id = "A1", x = 459.0, y = -994.0, z = 24.0},
        {id = "A2", x = 459.0, y = -997.0, z = 24.0},
        {id = "A3", x = 459.0, y = -1000.0, z = 24.0},
        {id = "A4", x = 459.0, y = -1003.0, z = 24.0},
        {id = "B1", x = 463.0, y = -994.0, z = 24.0},
        {id = "B2", x = 463.0, y = -997.0, z = 24.0},
        {id = "B3", x = 463.0, y = -1000.0, z = 24.0},
        {id = "B4", x = 463.0, y = -1003.0, z = 24.0}
    }
}

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

-- Calculate jail time based on charges
function calculateJailTime(charges, pleaGuilty)
    local totalTime = 0
    
    if not charges or #charges == 0 then
        return 0
    end
    
    for _, charge in ipairs(charges) do
        local baseTime = Config.Charges[charge] and Config.Charges[charge].baseTime or JailConfig.BaseTimePerCharge
        local multiplier = Config.Charges[charge] and Config.Charges[charge].multiplier or 1
        totalTime = totalTime + (baseTime * multiplier)
    end
    
    -- Apply plea reduction
    if pleaGuilty then
        totalTime = math.floor(totalTime * (1 - JailConfig.GuiltyPleaReduction))
    end
    
    -- Ensure max sentence
    totalTime = math.min(totalTime, JailConfig.MaxSentence)
    
    return totalTime
end

-- Get available cell
function getAvailableCell()
    local occupiedCells = executeQuery('SELECT cell_id FROM zmdt_custody WHERE status = ?', {'active'})
    local occupiedSet = {}
    
    for _, cell in ipairs(occupiedCells) do
        occupiedSet[cell.cell_id] = true
    end
    
    for _, cell in ipairs(JailConfig.Cells) do
        if not occupiedSet[cell.id] then
            return cell
        end
    end
    
    return nil
end

-- Create custody and jail
RegisterServerEvent('zmdt:server:createCustodyAndJail')
AddEventHandler('zmdt:server:createCustodyAndJail', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    -- Validate required fields
    if not data.citizenid or not data.charges or #data.charges == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Missing required fields', 'error')
        return
    end
    
    -- Calculate jail time
    local jailTime = calculateJailTime(data.charges, data.pleaGuilty)
    
    -- Get available cell
    local cell = getAvailableCell()
    if not cell then
        TriggerClientEvent('QBCore:Notify', src, 'No available cells', 'error')
        return
    end
    
    -- Insert custody record
    local success = executeInsert([[
        INSERT INTO zmdt_custody (citizenid, officer_id, cell_id, charges, jail_time, start_time, end_time, status, notes)
        VALUES (?, ?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? SECOND), ?, ?)
    ]], {
        data.citizenid,
        Player.PlayerData.citizenid,
        cell.id,
        json.encode(data.charges),
        jailTime,
        jailTime,
        'active',
        data.notes or ''
    })
    
    if success then
        -- Jail the player
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.citizenid)
        if targetPlayer then
            -- Set player in jail
            TriggerClientEvent('zmdt:client:jailPlayer', targetPlayer.PlayerData.source, {
                cell = cell,
                time = jailTime,
                charges = data.charges
            })
            
            -- Update player state
            targetPlayer.Functions.SetMetaData('injail', true)
            targetPlayer.Functions.SetMetaData('jailtime', jailTime)
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'Player jailed successfully', 'success')
        TriggerClientEvent('zmdt:client:custodyCreated', src, data.citizenid)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to create custody record', 'error')
    end
end)

-- Release from custody
RegisterServerEvent('zmdt:server:releaseFromCustody')
AddEventHandler('zmdt:server:releaseFromCustody', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    if not data.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Missing citizen ID', 'error')
        return
    end
    
    -- Update custody record
    local success = executeQuery([[
        UPDATE zmdt_custody 
        SET status = ?, end_time = NOW(), notes = CONCAT(notes, ' - Released by ', ?)
        WHERE citizenid = ? AND status = ?
    ]], {
        'released',
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        data.citizenid,
        'active'
    })
    
    if success then
        -- Release player from jail
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.citizenid)
        if targetPlayer then
            TriggerClientEvent('zmdt:client:releasePlayer', targetPlayer.PlayerData.source)
            
            -- Update player state
            targetPlayer.Functions.SetMetaData('injail', false)
            targetPlayer.Functions.SetMetaData('jailtime', 0)
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'Player released successfully', 'success')
        TriggerClientEvent('zmdt:client:custodyReleased', src, data.citizenid)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to release player', 'error')
    end
end)

-- Get jail configuration
RegisterServerEvent('zmdt:server:getJailConfig')
AddEventHandler('zmdt:server:getJailConfig', function()
    local src = source
    TriggerClientEvent('zmdt:client:jailConfig', src, {
        success = true,
        config = {
            baseTime = JailConfig.BaseTimePerCharge or 300,
            pleaReduction = (JailConfig.GuiltyPleaReduction or 0.25) * 100,
            maxSentence = JailConfig.MaxSentence or 7200,
            cells = JailConfig.Cells
        }
    })
end)

-- Calculate jail time
RegisterServerEvent('zmdt:server:calculateJailTime')
AddEventHandler('zmdt:server:calculateJailTime', function(data)
    local src = source
    
    if not data.charges or #data.charges == 0 then
        TriggerClientEvent('zmdt:client:jailTimeCalculated', src, {success = false, message = 'No charges provided'})
        return
    end
    
    local totalTime = calculateJailTime(data.charges, data.pleaGuilty)
    
    TriggerClientEvent('zmdt:client:jailTimeCalculated', src, {
        success = true,
        time = totalTime,
        charges = data.charges,
        pleaGuilty = data.pleaGuilty
    })
end)

-- Get custody records
RegisterServerEvent('zmdt:server:getCustodyRecords')
AddEventHandler('zmdt:server:getCustodyRecords', function()
    local src = source
    
    local records = executeQuery([[
        SELECT c.*, p.firstname, p.lastname 
        FROM zmdt_custody c 
        LEFT JOIN players p ON c.citizenid = p.citizenid 
        WHERE c.status = ? 
        ORDER BY c.start_time DESC
    ]], {'active'})
    
    TriggerClientEvent('zmdt:client:custodyRecords', src, records or {})
end)

-- Get remaining jail time
RegisterServerEvent('zmdt:server:getRemainingJailTime')
AddEventHandler('zmdt:server:getRemainingJailTime', function(citizenid)
    local src = source
    
    local jailingData = executeQuery([[
        SELECT * FROM zmdt_custody 
        WHERE citizenid = ? AND status = ? 
        ORDER BY start_time DESC 
        LIMIT 1
    ]], {citizenid, 'active'})
    
    if jailingData and #jailingData > 0 then
        local remaining = jailingData[1].end_time - os.time()
        TriggerClientEvent('zmdt:client:remainingJailTime', src, {
            success = true,
            time = math.max(0, remaining)
        })
    else
        TriggerClientEvent('zmdt:client:remainingJailTime', src, {
            success = false,
            message = 'No active jail time'
        })
    end
end)

-- Export functions
exports('calculateJailTime', calculateJailTime)
exports('getAvailableCell', getAvailableCell)