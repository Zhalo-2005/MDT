local QBCore = exports['qb-core']:GetCoreObject()

-- Get MDT Data
QBCore.Functions.CreateCallback('zmdt:server:getMDTData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    local data = {
        player = {
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            job = Player.PlayerData.job.name,
            grade = Player.PlayerData.job.grade.name,
            badge = Player.PlayerData.job.grade.level
        },
        charges = Config.Charges,
        permissions = GetPlayerPermissions(Player.PlayerData.job.name, Player.PlayerData.job.grade.level)
    }
    
    cb(data)
end)

function GetPlayerPermissions(job, grade)
    if Config.AuthorizedJobs[job] then
        return Config.AuthorizedJobs[job].permissions
    end
    return {}
end

-- Search Person
QBCore.Functions.CreateCallback('zmdt:server:searchPerson', function(source, cb, query)
    local result = MySQL.query.await('SELECT * FROM zmdt_citizens WHERE citizenid = ? OR CONCAT(firstname, " ", lastname) LIKE ?', {
        query, '%' .. query .. '%'
    })
    
    if result and #result > 0 then
        local person = result[1]
        
        -- Get additional data
        local fines = MySQL.query.await('SELECT * FROM zmdt_fines WHERE citizenid = ? ORDER BY created_at DESC', {person.citizenid})
        local warrants = MySQL.query.await('SELECT * FROM zmdt_warrants WHERE citizenid = ? AND status = "active"', {person.citizenid})
        local incidents = MySQL.query.await('SELECT * FROM zmdt_incidents WHERE involved_citizens LIKE ? ORDER BY created_at DESC LIMIT 10', {'%' .. person.citizenid .. '%'})
        
        person.fines = fines
        person.warrants = warrants
        person.incidents = incidents
        
        cb({success = true, data = person})
    else
        -- Try to get from players table
        local playerResult = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {query})
        if playerResult and #playerResult > 0 then
            local playerData = json.decode(playerResult[1].charinfo)
            
            -- Create citizen record
            MySQL.insert('INSERT INTO zmdt_citizens (citizenid, firstname, lastname, dob, phone) VALUES (?, ?, ?, ?, ?)', {
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
            cb({success = false, message = 'Person not found'})
        end
    end
end)

-- Search Vehicle
QBCore.Functions.CreateCallback('zmdt:server:searchVehicle', function(source, cb, query)
    local result = MySQL.query.await('SELECT * FROM zmdt_vehicles WHERE plate = ?', {query})
    
    if result and #result > 0 then
        local vehicle = result[1]
        
        -- Get incidents involving this vehicle
        local incidents = MySQL.query.await('SELECT * FROM zmdt_incidents WHERE involved_vehicles LIKE ? ORDER BY created_at DESC LIMIT 10', {'%' .. query .. '%'})
        vehicle.incidents = incidents
        
        cb({success = true, data = vehicle})
    else
        -- Try to get from player_vehicles table
        local vehicleResult = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ?', {query})
        if vehicleResult and #vehicleResult > 0 then
            local vehData = vehicleResult[1]
            
            -- Create vehicle record
            MySQL.insert('INSERT INTO zmdt_vehicles (plate, model, owner) VALUES (?, ?, ?)', {
                query,
                vehData.vehicle,
                vehData.citizenid
            })
            
            cb({success = true, data = {
                plate = query,
                model = vehData.vehicle,
                owner = vehData.citizenid,
                stolen = false,
                impounded = false,
                incidents = {}
            }})
        else
            cb({success = false, message = 'Vehicle not found'})
        end
    end
end)

-- Create Incident
RegisterNetEvent('zmdt:server:createIncident', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local incidentId = 'INC-' .. math.random(100000, 999999)
    
    MySQL.insert('INSERT INTO zmdt_incidents (incident_id, title, description, location, coords, officer_id, officer_name, priority, type, involved_citizens, involved_vehicles) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        incidentId,
        data.title,
        data.description,
        data.location,
        json.encode(data.coords),
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        data.priority or 'medium',
        data.type or 'police',
        json.encode(data.involved_citizens or {}),
        json.encode(data.involved_vehicles or {})
    })
    
    -- Send webhook
    SendWebhook('incidents', {
        title = 'New Incident Created',
        description = data.title,
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        incident_id = incidentId
    })
    
    -- Log action
    LogAction(src, 'CREATE_INCIDENT', 'Created incident: ' .. incidentId)
    
    TriggerClientEvent('QBCore:Notify', src, 'Incident created successfully', 'success')
end)

-- Issue Fine
RegisterNetEvent('zmdt:server:issueFine', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local fineId = 'FINE-' .. math.random(100000, 999999)
    local totalAmount = 0
    local totalPoints = 0
    
    -- Calculate totals
    for _, charge in pairs(data.charges) do
        totalAmount = totalAmount + charge.fine
        totalPoints = totalPoints + charge.points
    end
    
    -- Create payment coordinates (courthouse or police station)
    local paymentCoords = vector3(240.06, -1074.73, 29.29) -- Default courthouse
    
    MySQL.insert('INSERT INTO zmdt_fines (fine_id, citizenid, charges, total_amount, penalty_points, issued_by, issued_by_name, payment_coords, due_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        fineId,
        data.citizenid,
        json.encode(data.charges),
                totalAmount,
        totalPoints,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        json.encode(paymentCoords),
        os.date('%Y-%m-%d %H:%M:%S', os.time() + (7 * 24 * 60 * 60)) -- 7 days from now
    })
    
    -- Update citizen penalty points
    MySQL.query('UPDATE zmdt_citizens SET penalty_points = penalty_points + ? WHERE citizenid = ?', {
        totalPoints, data.citizenid
    })
    
    -- Create blip for payment
    TriggerClientEvent('zmdt:client:createFineBlip', -1, paymentCoords, fineId)
    
    -- Notify target player if online
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.citizenid)
    if targetPlayer then
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have received a fine of $' .. totalAmount, 'error', 10000)
    end
    
    -- Send webhook
    SendWebhook('fines', {
        title = 'Fine Issued',
        citizenid = data.citizenid,
        amount = totalAmount,
        points = totalPoints,
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        fine_id = fineId
    })
    
    -- Log action
    LogAction(src, 'ISSUE_FINE', 'Issued fine: ' .. fineId .. ' to ' .. data.citizenid)
    
    TriggerClientEvent('QBCore:Notify', src, 'Fine issued successfully', 'success')
end)

-- Create Warrant
RegisterNetEvent('zmdt:server:createWarrant', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local warrantId = 'WAR-' .. math.random(100000, 999999)
    
    MySQL.insert('INSERT INTO zmdt_warrants (warrant_id, citizenid, charges, description, issued_by, issued_by_name, bail_amount) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        warrantId,
        data.citizenid,
        json.encode(data.charges),
        data.description,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        data.bail_amount or 0
    })
    
    -- Send webhook
    SendWebhook('warrants', {
        title = 'Warrant Issued',
        citizenid = data.citizenid,
        charges = data.charges,
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        warrant_id = warrantId
    })
    
    -- Log action
    LogAction(src, 'CREATE_WARRANT', 'Created warrant: ' .. warrantId .. ' for ' .. data.citizenid)
    
    TriggerClientEvent('QBCore:Notify', src, 'Warrant created successfully', 'success')
end)

-- Create Custody Record
RegisterNetEvent('zmdt:server:createCustody', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local targetPlayer = QBCore.Functions.GetPlayer(data.targetId)
    if not targetPlayer then return end
    
    MySQL.insert('INSERT INTO zmdt_custody (citizenid, charges, arresting_officer, officer_name, custody_time, bail_amount, cell_number) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        targetPlayer.PlayerData.citizenid,
        json.encode(data.charges),
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        data.custody_time or 300, -- 5 minutes default
        data.bail_amount or 0,
        data.cell_number or math.random(1, 10)
    })
    
    -- Send webhook
    SendWebhook('custody', {
        title = 'Person In Custody',
        citizenid = targetPlayer.PlayerData.citizenid,
        charges = data.charges,
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        custody_time = data.custody_time or 300
    })
    
    -- Log action
    LogAction(src, 'CREATE_CUSTODY', 'Put ' .. targetPlayer.PlayerData.citizenid .. ' in custody')
    
    TriggerClientEvent('QBCore:Notify', src, 'Custody record created', 'success')
end)

-- Create Medical Incident
RegisterNetEvent('zmdt:server:createMedicalIncident', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local incidentId = 'MED-' .. math.random(100000, 999999)
    
    MySQL.insert('INSERT INTO zmdt_incidents (incident_id, title, description, location, coords, officer_id, officer_name, type, priority) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        incidentId,
        'Medical Treatment - ' .. (data.treatment or 'General'),
        data.description or 'Patient treated by EMS',
        data.location or 'Unknown Location',
        json.encode(data.coords or GetEntityCoords(GetPlayerPed(src))),
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        'medical',
        'medium'
    })
    
    -- Send webhook
    SendWebhook('medical', {
        title = 'Medical Incident',
        treatment = data.treatment,
        medic = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        incident_id = incidentId
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Medical incident logged', 'success')
end)

-- Dispatch System
RegisterNetEvent('zmdt:server:createDispatchCall', function(data)
    local src = source
    local callId = 'CALL-' .. math.random(100000, 999999)
    
    local coords = data.coords
    if type(coords) == 'table' and coords.x then
        coords = json.encode(coords)
    end
    
    MySQL.insert('INSERT INTO zmdt_dispatch_calls (call_id, title, description, location, coords, caller, priority, type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        callId,
        data.title,
        data.description,
        data.location or 'Unknown Location',
        coords,
        data.caller or 'Anonymous',
        data.priority or 'medium',
        data.type or 'police'
    })
    
    -- Send to all authorized players
    local callData = {
        call_id = callId,
        title = data.title,
        description = data.description,
        location = data.location or 'Unknown Location',
        coords = json.decode(coords),
        caller = data.caller or 'Anonymous',
        priority = data.priority or 'medium',
        type = data.type or 'police',
        status = 'pending',
        created_at = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    -- Send to appropriate job types
    local targetJobs = {'police', 'sheriff'}
    if data.type == 'medical' then
        targetJobs = {'ambulance'}
    elseif data.type == 'fire' then
        targetJobs = {'fire'}
    end
    
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            for _, job in pairs(targetJobs) do
                if Player.PlayerData.job.name == job and Player.PlayerData.job.onduty then
                    TriggerClientEvent('zmdt:dispatch:newCall', playerId, callData)
                    break
                end
            end
        end
    end
end)

RegisterNetEvent('zmdt:server:acceptDispatch', function(callId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Update call status
    MySQL.query('UPDATE zmdt_dispatch_calls SET status = "assigned", assigned_units = ? WHERE call_id = ?', {
        json.encode({Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname}),
        callId
    })
    
    -- Notify other units
    TriggerClientEvent('zmdt:dispatch:updateCall', -1, callId, {
        status = 'assigned',
        assigned_units = {Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname}
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Dispatch call accepted', 'success')
end)

RegisterNetEvent('zmdt:server:closeDispatch', function(callId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Update call status
    MySQL.query('UPDATE zmdt_dispatch_calls SET status = "closed" WHERE call_id = ?', {callId})
    
    -- Notify all units
    TriggerClientEvent('zmdt:dispatch:updateCall', -1, callId, {status = 'closed'})
    
    TriggerClientEvent('QBCore:Notify', src, 'Dispatch call closed', 'success')
end)

-- Fine Payment System
RegisterNetEvent('zmdt:server:payFine', function(fineId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local fine = MySQL.query.await('SELECT * FROM zmdt_fines WHERE fine_id = ? AND status = "unpaid"', {fineId})
    if not fine or #fine == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Fine not found or already paid', 'error')
        return
    end
    
    local fineData = fine[1]
    local amount = fineData.total_amount
    
    -- Check if player has enough money
    local bankBalance = Player.PlayerData.money['bank']
    if bankBalance < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Insufficient funds', 'error')
        return
    end
    
    -- Process payment
    Player.Functions.RemoveMoney('bank', amount, 'fine-payment')
    
    -- Update fine status
    MySQL.query('UPDATE zmdt_fines SET status = "paid", paid_at = NOW() WHERE fine_id = ?', {fineId})
    
    -- Remove blip
    TriggerClientEvent('zmdt:client:removeFineBlip', -1, fineId)
    
    -- Add money to government account (if using qb-management)
    if Config.Integrations.Banking == 'qb-management' then
        exports['qb-management']:AddMoney('police', amount)
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Fine paid successfully', 'success')
end)

-- Utility Functions
function SendWebhook(type, data)
    if not Config.Webhooks[type] or Config.Webhooks[type] == '' then return end
    
    local embed = {
        {
            title = data.title,
            description = data.description or '',
            color = 3447003,
            fields = {},
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }
    
    -- Add fields based on type
    for k, v in pairs(data) do
        if k ~= 'title' and k ~= 'description' then
            table.insert(embed[1].fields, {
                name = k:gsub('_', ' '):gsub('^%l', string.upper),
                value = tostring(v),
                inline = true
            })
        end
    end
    
    PerformHttpRequest(Config.Webhooks[type], function(err, text, headers) end, 'POST', json.encode({
        username = 'Z-MDT System',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
    
    -- Google Sheets integration
    if Config.GoogleSheets.enabled and Config.GoogleSheets.webhook_url ~= '' then
        PerformHttpRequest(Config.GoogleSheets.webhook_url, function(err, text, headers) end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
    end
end

function LogAction(source, action, details)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    MySQL.insert('INSERT INTO zmdt_audit_logs (action, user_id, user_name, details, ip_address) VALUES (?, ?, ?, ?, ?)', {
        action,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        details,
        GetPlayerEndpoint(source)
    })
end

-- Commands
QBCore.Commands.Add('mdt', 'Open MDT Tablet', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if player has tablet item
    local hasTablet = Player.Functions.GetItemByName(Config.TabletItem)
    if not hasTablet then
        TriggerClientEvent('QBCore:Notify', source, 'You need an MDT tablet', 'error')
        return
    end
    
    TriggerClientEvent('zmdt:client:useTablet', source)
end)

QBCore.Commands.Add('dispatch', 'Create dispatch call', {{name = 'title', help = 'Call title'}, {name = 'description', help = 'Call description'}}, true, function(source, args)
    local title = args[1]
    local description = table.concat(args, ' ', 2)
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    TriggerEvent('zmdt:server:createDispatchCall', {
        title = title,
        description = description,
        coords = {x = coords.x, y = coords.y, z = coords.z},
        caller = 'System',
        priority = 'medium',
        type = 'police'
    })
end, 'admin')

-- Item Usage
QBCore.Functions.CreateUseableItem(Config.TabletItem, function(source, item)
    TriggerClientEvent('zmdt:client:useTablet', source)
end)

-- Player Loading
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    -- Check for unpaid fines and create blips
    local fines = MySQL.query.await('SELECT * FROM zmdt_fines WHERE citizenid = ? AND status = "unpaid"', {Player.PlayerData.citizenid})
    
    for _, fine in pairs(fines) do
        if fine.payment_coords then
            local coords = json.decode(fine.payment_coords)
            TriggerClientEvent('zmdt:client:createFineBlip', Player.PlayerData.source, coords, fine.fine_id)
        end
    end
end)

