-- Jail System Integration for MDT
local QBCore = exports['qb-core']:GetCoreObject()

-- Jail Configuration
local JailConfig = Config.Jail or {}
local activeJailings = {}

-- Calculate jail time based on charges
local function calculateJailTime(charges, pleaGuilty)
    if not charges or #charges == 0 then return 0 end
    
    local totalTime = 0
    local categoryMultipliers = Config.TimeMultipliers or {}
    local baseTime = JailConfig.BaseTimePerCharge or 300 -- 5 minutes default
    
    for _, charge in ipairs(charges) do
        local chargeCode = charge.code or charge.id or 'UNKNOWN'
        local multiplier = 1.0
        
        -- Determine category and multiplier
        for category, codes in pairs(Config.ChargeCategories or {}) do
            for _, code in ipairs(codes) do
                if code == chargeCode then
                    multiplier = categoryMultipliers[category] or 1.0
                    break
                end
            end
        end
        
        totalTime = totalTime + (baseTime * multiplier)
    end
    
    -- Apply guilty plea reduction
    if pleaGuilty and JailConfig.GuiltyPleaReduction then
        totalTime = totalTime * (1 - JailConfig.GuiltyPleaReduction)
    end
    
    -- Apply maximum sentence cap
    local maxSentence = JailConfig.MaxSentence or 3600 -- 1 hour default
    if totalTime > maxSentence then
        totalTime = maxSentence
    end
    
    return math.floor(totalTime)
end

-- Get available jail cell
local function getAvailableCell()
    local cells = JailConfig.Cells or {}
    if #cells == 0 then return nil end
    
    -- Check which cells are occupied
    local occupiedCells = {}
    local query = 'SELECT cell_number FROM zmdt_custody WHERE status = ?'
    local results = exports.oxmysql:execute_sync(query, {'in_custody'})
    
    if results then
        for _, result in ipairs(results) do
            occupiedCells[result.cell_number] = true
        end
    end
    
    -- Find first available cell
    for _, cell in ipairs(cells) do
        if not occupiedCells[cell.id] then
            return cell
        end
    end
    
    return nil -- No available cells
end

-- Jail player function
local function jailPlayer(citizenid, charges, time, cell, officer)
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not targetPlayer then
        return false, "Player not online"
    end
    
    local src = targetPlayer.PlayerData.source
    
    -- Set player in jail
    targetPlayer.Functions.SetMetaData("injail", time)
    targetPlayer.Functions.SetMetaData("jailitems", targetPlayer.PlayerData.items)
    targetPlayer.Functions.ClearInventory()
    
    -- Teleport to jail
    local jailLocation = JailConfig.DefaultLocation or vector3(459.5, -994.0, 24.9)
    if cell and cell.coords then
        jailLocation = cell.coords
    end
    
    SetEntityCoords(GetPlayerPed(src), jailLocation.x, jailLocation.y, jailLocation.z, false, false, false, true)
    
    -- Store jail data
    activeJailings[citizenid] = {
        startTime = os.time(),
        endTime = os.time() + time,
        charges = charges,
        cell = cell,
        officer = officer,
        originalTime = time
    }
    
    -- Send webhook
    SendWebhook('jail', {
        title = 'Player Jailed',
        citizenid = citizenid,
        name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
        time = time,
        charges = charges,
        officer = officer.name,
        cell = cell and cell.label or 'Default'
    })
    
    -- Log action
    LogAction(officer.source, 'JAIL_SENTENCE', 'Jailed ' .. citizenid .. ' for ' .. time .. ' seconds')
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', src, 'You have been sentenced to jail for ' .. math.floor(time/60) .. ' minutes', 'error', 10000)
    
    return true, "Player jailed successfully"
end

-- Release player from jail
local function releasePlayer(citizenid, reason, officer)
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not targetPlayer then
        return false, "Player not online"
    end
    
    local src = targetPlayer.PlayerData.source
    
    -- Clear jail metadata
    targetPlayer.Functions.SetMetaData("injail", 0)
    
    -- Restore inventory if stored
    local jailItems = targetPlayer.PlayerData.metadata["jailitems"]
    if jailItems then
        for _, item in pairs(jailItems) do
            targetPlayer.Functions.AddItem(item.name, item.amount, false, item.info)
        end
        targetPlayer.Functions.SetMetaData("jailitems", {})
    end
    
    -- Remove from active jailings
    activeJailings[citizenid] = nil
    
    -- Send webhook
    SendWebhook('jail', {
        title = 'Player Released',
        citizenid = citizenid,
        name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
        reason = reason,
        officer = officer and officer.name or 'System'
    })
    
    -- Log action
    if officer then
        LogAction(officer.source, 'RELEASE_JAIL', 'Released ' .. citizenid .. ' from jail')
    end
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', src, 'You have been released from jail', 'success', 5000)
    
    return true, "Player released successfully"
end

-- Check if player is in jail
local function isPlayerInJail(citizenid)
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not targetPlayer then return false end
    
    local injail = targetPlayer.PlayerData.metadata["injail"]
    return injail and injail > 0
end

-- Get remaining jail time
local function getRemainingJailTime(citizenid)
    local jailingData = activeJailings[citizenid]
    if not jailingData then return 0 end
    
    local remaining = jailingData.endTime - os.time()
    return remaining > 0 and remaining or 0
end

-- NUI Callback: Create Custody and Jail
RegisterNUICallback('createCustodyAndJail', function(data, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(data.targetId)
    if not targetPlayer then
        cb({success = false, message = 'Target player not found'})
        return
    end
    
    -- Validate charges
    if not data.charges or #data.charges == 0 then
        cb({success = false, message = 'No charges specified'})
        return
    end
    
    -- Calculate jail time
    local jailTime = calculateJailTime(data.charges, data.pleaGuilty)
    
    -- Get available cell
    local cell = getAvailableCell()
    if not cell then
        cb({success = false, message = 'No available jail cells'})
        return
    end
    
    -- Create custody record
    local custodyId = 'CUST-' .. math.random(100000, 999999)
    local success = exports.oxmysql:insert_sync(
        'INSERT INTO zmdt_custody (citizenid, charges, arresting_officer, officer_name, custody_time, bail_amount, cell_number, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            targetPlayer.PlayerData.citizenid,
            json.encode(data.charges),
            Player.PlayerData.citizenid,
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            jailTime,
            data.bail_amount or 0,
            cell.id,
            'in_custody'
        }
    )
    
    if not success then
        cb({success = false, message = 'Failed to create custody record'})
        return
    end
    
    -- Jail the player
    local officerData = {
        source = src,
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    }
    
    local jailed, message = jailPlayer(
        targetPlayer.PlayerData.citizenid,
        data.charges,
        jailTime,
        cell,
        officerData
    )
    
    if jailed then
        cb({
            success = true, 
            message = 'Player placed in custody and jailed',
            custody_id = custodyId,
            jail_time = jailTime,
            cell = cell.label
        })
    else
        cb({success = false, message = message})
    end
end)

-- NUI Callback: Release from Custody
RegisterNUICallback('releaseFromCustody', function(data, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return
    end
    
    local citizenid = data.citizenid
    if not citizenid then
        cb({success = false, message = 'No citizen ID provided'})
        return
    end
    
    -- Check if player is in custody
    local custody = exports.oxmysql:execute_sync(
        'SELECT * FROM zmdt_custody WHERE citizenid = ? AND status = ?',
        {citizenid, 'in_custody'}
    )
    
    if not custody or #custody == 0 then
        cb({success = false, message = 'Player not in custody'})
        return
    end
    
    -- Update custody record
    local success = exports.oxmysql:update_sync(
        'UPDATE zmdt_custody SET status = ?, released_at = NOW() WHERE citizenid = ? AND status = ?',
        {'released', citizenid, 'in_custody'}
    )
    
    if success then
        -- Release from jail if applicable
        local officerData = {
            source = src,
            citizenid = Player.PlayerData.citizenid,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        }
        
        local released, message = releasePlayer(citizenid, 'Released from custody', officerData)
        
        cb({
            success = true,
            message = 'Player released from custody' .. (released and ' and jail' or ''),
            released_from_jail = released
        })
    else
        cb({success = false, message = 'Failed to update custody record'})
    end
end)

-- NUI Callback: Get Jail Configuration
RegisterNUICallback('getJailConfig', function(data, cb)
    cb({
        success = true,
        config = {
            baseTime = JailConfig.BaseTimePerCharge or 300,
            pleaReduction = (JailConfig.GuiltyPleaReduction or 0.25) * 100,
            maxSentence = JailConfig.MaxSentence or 3600,
            cells = JailConfig.Cells or {}
        }
    })
end)

-- NUI Callback: Calculate Jail Time
RegisterNUICallback('calculateJailTime', function(data, cb)
    if not data.charges or #data.charges == 0 then
        cb({success = false, message = 'No charges provided'})
        return
    end
    
    local time = calculateJailTime(data.charges, data.pleaGuilty)
    
    cb({
        success = true,
        time = time,
        displayTime = formatTime(time)
    })
end)

-- Format time for display
function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

-- Check jail times periodically
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        for citizenid, data in pairs(activeJailings) do
            local remaining = data.endTime - os.time()
            
            if remaining <= 0 then
                -- Time served, release player
                releasePlayer(citizenid, 'Time served', nil)
            elseif remaining == 300 then
                -- 5 minutes remaining warning
                local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
                if targetPlayer then
                    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, '5 minutes remaining in jail', 'info', 5000)
                end
            end
        end
    end
end)

-- Command to release from jail
QBCore.Commands.Add('release', 'Release player from jail', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found', 'error')
        return
    end
    
    local officerData = {
        source = source,
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    }
    
    local released, message = releasePlayer(targetPlayer.PlayerData.citizenid, 'Administrative release', officerData)
    
    if released then
        TriggerClientEvent('QBCore:Notify', source, 'Player released from jail', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, message, 'error')
    end
end, 'admin')

-- Export functions
exports('jailPlayer', jailPlayer)
exports('releasePlayer', releasePlayer)
exports('isPlayerInJail', isPlayerInJail)
exports('getRemainingJailTime', getRemainingJailTime)
exports('calculateJailTime', calculateJailTime)