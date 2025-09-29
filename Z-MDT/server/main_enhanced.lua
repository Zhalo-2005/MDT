-- Enhanced Z-MDT Server Main File
-- This file contains all the enhanced server-side functionality

local QBCore = exports['qb-core']:GetCoreObject()
local isQBCore = true

-- Performance optimization
local cachedData = {}
local updateQueue = {}
local lastUpdate = 0

-- Initialize the system
CreateThread(function()
    Wait(1000)
    print('[^2Z-MDT^7] Enhanced MDT System initializing...')
    
    -- Load job ranks from qb-core
    LoadJobRanks()
    
    -- Initialize department accounts
    InitializeDepartmentAccounts()
    
    -- Start real-time update system
    StartRealTimeUpdates()
    
    -- Start performance monitoring
    StartPerformanceMonitoring()
    
    print('[^2Z-MDT^7] System initialization complete!')
end)

-- Load job ranks from qb-core
function LoadJobRanks()
    if not Config.AuthorizedJobs then return end
    
    for jobName, jobData in pairs(Config.AuthorizedJobs) do
        if jobData.auto_detect_ranks then
            local jobInfo = QBCore.Shared.Jobs[jobName]
            if jobInfo and jobInfo.grades then
                for gradeLevel, gradeData in pairs(jobInfo.grades) do
                    local permissions = jobData.permissions or {}
                    local mdtPermissions = table.concat(permissions, ',')
                    
                    MySQL.insert('INSERT IGNORE INTO zmdt_job_ranks (job_name, grade_level, grade_name, label, permissions, mdt_permissions) VALUES (?, ?, ?, ?, ?, ?)', {
                        jobName,
                        tonumber(gradeLevel),
                        gradeData.name or 'grade'..gradeLevel,
                        gradeData.label or 'Grade '..gradeLevel,
                        json.encode(permissions),
                        mdtPermissions
                    })
                end
            end
        end
    end
end

-- Initialize department accounts
function InitializeDepartmentAccounts()
    local accounts = MySQL.query.await('SELECT * FROM zmdt_department_accounts')
    if not accounts or #accounts == 0 then
        MySQL.insert('INSERT INTO zmdt_department_accounts (account_id, department, account_type, balance) VALUES (?, ?, ?, ?)', {
            'GOVERNMENT_ACCOUNT', 'government', 'general', 1000000.00
        })
        MySQL.insert('INSERT INTO zmdt_department_accounts (account_id, department, account_type, balance) VALUES (?, ?, ?, ?)', {
            'POLICE_ACCOUNT', 'police', 'general', 500000.00
        })
    end
end

-- Enhanced Get MDT Data
QBCore.Functions.CreateCallback('zmdt:server:getMDTData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    local jobRanks = MySQL.query.await('SELECT * FROM zmdt_job_ranks WHERE job_name = ? AND grade_level = ?', {
        Player.PlayerData.job.name,
        Player.PlayerData.job.grade.level
    })
    
    local permissions = {}
    if jobRanks and #jobRanks > 0 then
        permissions = json.decode(jobRanks[1].mdt_permissions or '[]')
    else
        permissions = GetPlayerPermissions(Player.PlayerData.job.name, Player.PlayerData.job.grade.level)
    end
    
    local data = {
        player = {
            citizenid = Player.PlayerData.citizenid,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            job = Player.PlayerData.job.name,
            grade = Player.PlayerData.job.grade.name,
            grade_level = Player.PlayerData.job.grade.level,
            badge = Player.PlayerData.job.grade.level,
            permissions = permissions,
            is_boss = Player.PlayerData.job.grade.level >= (Config.AuthorizedJobs[Player.PlayerData.job.name]?.min_grade_for_boss or 99),
            is_high_command = Player.PlayerData.job.grade.level >= (Config.AuthorizedJobs[Player.PlayerData.job.name]?.min_grade_for_high_command or 99)
        },
        charges = Config.Charges,
        server_time = os.time(),
        server_stats = GetServerStats(),
        online_players = GetOnlinePlayersData()
    }
    
    cb(data)
end)

-- Enhanced Search Person with Real-time Data
QBCore.Functions.CreateCallback('zmdt:server:searchPerson', function(source, cb, query)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({success = false, message = 'Player not found'}) end
    
    -- Search in database
    local result = MySQL.query.await([[
        SELECT * FROM zmdt_citizens 
        WHERE citizenid = ? OR CONCAT(firstname, ' ', lastname) LIKE ? OR phone = ? OR email = ?
    ]], {query, '%' .. query .. '%', query, query})
    
    if result and #result > 0 then
        local person = result[1]
        
        -- Get additional data
        person.fines = MySQL.query.await('SELECT * FROM zmdt_fines WHERE citizenid = ? ORDER BY created_at DESC LIMIT 20', {person.citizenid})
        person.warrants = MySQL.query.await('SELECT * FROM zmdt_warrants WHERE citizenid = ? AND status = "active"', {person.citizenid})
        person.incidents = MySQL.query.await('SELECT * FROM zmdt_incidents WHERE involved_citizens LIKE ? ORDER BY created_at DESC LIMIT 10', {'%' .. person.citizenid .. '%'})
        person.custody_records = MySQL.query.await('SELECT * FROM zmdt_custody WHERE citizenid = ? ORDER BY arrest_date DESC LIMIT 5', {person.citizenid})
        person.medical_records = MySQL.query.await('SELECT * FROM zmdt_medical_records WHERE citizenid = ? ORDER BY created_at DESC LIMIT 5', {person.citizenid})
        person.vehicles = MySQL.query.await('SELECT * FROM zmdt_vehicles WHERE owner = ? OR co_owner = ?', {person.citizenid, person.citizenid})
        person.evidence = MySQL.query.await('SELECT * FROM zmdt_evidence WHERE case_id IN (SELECT incident_id FROM zmdt_incidents WHERE involved_citizens LIKE ?)', {'%' .. person.citizenid .. '%'})
        
        -- Get current status if online
        local onlinePlayer = QBCore.Functions.GetPlayerByCitizenId(person.citizenid)
        if onlinePlayer then
            person.online_status = {
                is_online = true,
                server_id = onlinePlayer.PlayerData.source,
                current_location = GetEntityCoords(GetPlayerPed(onlinePlayer.PlayerData.source)),
                health = GetEntityHealth(GetPlayerPed(onlinePlayer.PlayerData.source)),
                armor = GetPedArmour(GetPlayerPed(onlinePlayer.PlayerData.source))
            }
        else
            person.online_status = {is_online = false}
        end
        
        LogAction(source, 'SEARCH_PERSON', 'Searched for person: ' .. person.citizenid)
        cb({success = true, data = person})
    else
        -- Try to get from players table and create record
        local playerResult = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {query})
        if playerResult and #playerResult > 0 then
            local playerData = json.decode(playerResult[1].charinfo)
            local jobData = json.decode(playerResult[1].job)
            
            MySQL.insert('INSERT INTO zmdt_citizens (citizenid, firstname, lastname, dob, phone, email, occupation, nationality) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                query,
                playerData.firstname,
                playerData.lastname,
                playerData.birthdate,
                playerData.phone,
                playerData.email or '',
                jobData.label or 'Unemployed',
                'American'
            })
            
            cb({success = true, data = {
                citizenid = query,
                firstname = playerData.firstname,
                lastname = playerData.lastname,
                dob = playerData.birthdate,
                phone = playerData.phone,
                email = playerData.email or '',
                occupation = jobData.label or 'Unemployed',
                nationality = 'American',
                penalty_points = 0,
                criminal_record = 'clean',
                risk_level = 'low',
                fines = {},
                warrants = {},
                incidents = {},
                custody_records = {},
                medical_records = {},
                vehicles = {},
                evidence = {},
                online_status = {is_online = false}
            }})
        else
            cb({success = false, message = 'Person not found'})
        end
    end
end)

-- Enhanced Search Vehicle with JG-Dealership Integration
QBCore.Functions.CreateCallback('zmdt:server:searchVehicle', function(source, cb, query)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({success = false, message = 'Player not found'}) end
    
    -- Search in MDT database
    local result = MySQL.query.await([[
        SELECT * FROM zmdt_vehicles 
        WHERE plate = ? OR vin = ?
    ]], {query, query})
    
    if result and #result > 0 then
        local vehicle = result[1]
        
        -- Get incidents involving this vehicle
        vehicle.incidents = MySQL.query.await('SELECT * FROM zmdt_incidents WHERE involved_vehicles LIKE ? ORDER BY created_at DESC LIMIT 10', {'%' .. query .. '%'})
        vehicle.fines = MySQL.query.await('SELECT * FROM zmdt_fines WHERE citizenid = ?', {vehicle.owner})
        
        -- Get owner information
        vehicle.owner_info = MySQL.query.await('SELECT * FROM zmdt_citizens WHERE citizenid = ?', {vehicle.owner})
        if vehicle.owner_info and #vehicle.owner_info > 0 then
            vehicle.owner_info = vehicle.owner_info[1]
        end
        
        -- Get JG-Dealership data if available
        if Config.Integrations.Dealership then
            local dealershipData = GetDealershipData(vehicle.plate)
            if dealershipData then
                vehicle.dealership_info = dealershipData
            end
        end
        
        LogAction(source, 'SEARCH_VEHICLE', 'Searched for vehicle: ' .. query)
        cb({success = true, data = vehicle})
    else
        -- Try to get from player_vehicles and create record
        local vehicleResult = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ?', {query})
        if vehicleResult and #vehicleResult > 0 then
            local vehData = vehicleResult[1]
            
            MySQL.insert('INSERT INTO zmdt_vehicles (plate, model, owner, vin, color, vehicle_type) VALUES (?, ?, ?, ?, ?, ?)', {
                query,
                vehData.vehicle,
                vehData.citizenid,
                vehData.vehicle .. '_' .. query,
                'Unknown',
                'car'
            })
            
            cb({success = true, data = {
                plate = query,
                model = vehData.vehicle,
                owner = vehData.citizenid,
                vin = vehData.vehicle .. '_' .. query,
                color = 'Unknown',
                vehicle_type = 'car',
                stolen = false,
                impounded = false,
                registration_status = 'valid',
                incidents = {},
                fines = {},
                owner_info = {}
            }})
        else
            cb({success = false, message = 'Vehicle not found'})
        end
    end
end)

-- Enhanced Create Incident with Photos and Evidence
RegisterNetEvent('zmdt:server:createIncident', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local incidentId = 'INC-' .. os.time() .. '-' .. math.random(1000, 9999)
    
    MySQL.insert('INSERT INTO zmdt_incidents (incident_id, title, description, location, coords, officer_id, officer_name, priority, type, category, involved_citizens, involved_vehicles, involved_officers, witnesses, evidence, photos, weather_conditions, lighting_conditions, road_conditions) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        incidentId,
        data.title,
        data.description,
        data.location,
        json.encode(data.coords or {}),
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        data.priority or 'medium',
        data.type or 'police',
        data.category or 'general',
        json.encode(data.involved_citizens or {}),
        json.encode(data.involved_vehicles or {}),
        json.encode(data.involved_officers or {}),
        json.encode(data.witnesses or {}),
        json.encode(data.evidence or {}),
        json.encode(data.photos or {}),
        data.weather_conditions or 'Clear',
        data.lighting_conditions or 'Daylight',
        data.road_conditions or 'Dry'
    })
    
    -- Send webhook
    SendWebhook('incidents', {
        title = 'New Incident Created',
        description = data.title,
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        incident_id = incidentId,
        priority = data.priority or 'medium',
        location = data.location
    })
    
    -- Log action
    LogAction(src, 'CREATE_INCIDENT', 'Created incident: ' .. incidentId)
    
    -- Update real-time for all players
    UpdateRealTimeData('incident_created', {
        incident_id = incidentId,
        data = data
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Incident created successfully', 'success')
end)

-- Enhanced Issue Fine with Government Tax System
RegisterNetEvent('zmdt:server:issueFine', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local fineId = 'FINE-' .. os.time() .. '-' .. math.random(1000, 9999)
    local totalAmount = 0
    local totalPoints = 0
    
    -- Calculate totals
    for _, charge in pairs(data.charges) do
        totalAmount = totalAmount + (charge.fine or 0)
        totalPoints = totalPoints + (charge.points or 0)
    end
    
    -- Calculate government tax and PD amount
    local governmentTax = totalAmount * Config.GovernmentTax.tax_rate
    local pdAmount = totalAmount - governmentTax
    
    -- Create payment coordinates
    local paymentCoords = vector3(240.06, -1074.73, 29.29)
    
    MySQL.insert('INSERT INTO zmdt_fines (fine_id, citizenid, charges, total_amount, penalty_points, government_tax, pd_amount, issued_by, issued_by_name, payment_coords, due_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        fineId,
        data.citizenid,
        json.encode(data.charges),
        totalAmount,
        totalPoints,
        governmentTax,
        pdAmount,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        json.encode(paymentCoords),
        os.date('%Y-%m-%d %H:%M:%S', os.time() + (7 * 24 * 60 * 60))
    })
    
    -- Update citizen penalty points
    MySQL.query('UPDATE zmdt_citizens SET penalty_points = penalty_points + ? WHERE citizenid = ?', {
        totalPoints, data.citizenid
    })
    
    -- Process financial transaction
    ProcessFinancialTransaction({
        type = 'fine_issued',
        fine_id = fineId,
        amount = totalAmount,
        government_tax = governmentTax,
        pd_amount = pdAmount,
        citizenid = data.citizenid,
        issued_by = Player.PlayerData.citizenid
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
        government_tax = governmentTax,
        pd_amount = pdAmount,
        points = totalPoints,
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        fine_id = fineId
    })
    
    -- Log action
    LogAction(src, 'ISSUE_FINE', 'Issued fine: ' .. fineId .. ' to ' .. data.citizenid .. ' for $' .. totalAmount)
    
    TriggerClientEvent('QBCore:Notify', src, 'Fine issued successfully', 'success')
end)

-- Enhanced Fine Payment with Government Tax Distribution
RegisterNetEvent('zmdt:server:payFine', function(fineId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local fine = MySQL.query.await('SELECT * FROM zmdt_fines WHERE fine_id = ? AND status = "unpaid"', {fineId})
    if not fine or #fine == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Fine not found or already paid', 'error')
        return
    end
    
    local fineData = fine[0]
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
    MySQL.query('UPDATE zmdt_fines SET status = "paid", payment_date = NOW(), total_paid = ? WHERE fine_id = ?', {
        amount, fineId
    })
    
    -- Process financial transaction for payment
    ProcessFinancialTransaction({
        type = 'fine_payment',
        fine_id = fineId,
        amount = amount,
        government_tax = fineData.government_tax,
        pd_amount = fineData.pd_amount,
        citizenid = Player.PlayerData.citizenid,
        payment_method = 'bank'
    })
    
    -- Remove blip
    TriggerClientEvent('zmdt:client:removeFineBlip', -1, fineId)
    
    -- Send webhook
    SendWebhook('fines', {
        title = 'Fine Paid',
        fine_id = fineId,
        amount = amount,
        citizenid = Player.PlayerData.citizenid,
        citizen_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Fine paid successfully', 'success')
end)

-- Enhanced Create Warrant
RegisterNetEvent('zmdt:server:createWarrant', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local warrantId = 'WAR-' .. os.time() .. '-' .. math.random(1000, 9999)
    
    MySQL.insert('INSERT INTO zmdt_warrants (warrant_id, citizenid, charges, description, warrant_type, priority, issued_by, issued_by_name, bail_amount, bond_amount, expiration_date, danger_level) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        warrantId,
        data.citizenid,
        json.encode(data.charges),
        data.description,
        data.warrant_type or 'arrest',
        data.priority or 'medium',
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        data.bail_amount or 0,
        data.bond_amount or 0,
        os.date('%Y-%m-%d %H:%M:%S', os.time() + (30 * 24 * 60 * 60)), -- 30 days
        data.danger_level or 'medium'
    })
    
    -- Send webhook
    SendWebhook('warrants', {
        title = 'Warrant Issued',
        citizenid = data.citizenid,
        warrant_type = data.warrant_type or 'arrest',
        priority = data.priority or 'medium',
        danger_level = data.danger_level or 'medium',
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        warrant_id = warrantId
    })
    
    -- Log action
    LogAction(src, 'CREATE_WARRANT', 'Created warrant: ' .. warrantId .. ' for ' .. data.citizenid)
    
    -- Update real-time
    UpdateRealTimeData('warrant_created', {
        warrant_id = warrantId,
        data = data
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Warrant created successfully', 'success')
end)

-- Enhanced Create Custody Record
RegisterNetEvent('zmdt:server:createCustody', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local targetPlayer = QBCore.Functions.GetPlayer(data.targetId)
    if not targetPlayer then 
        TriggerClientEvent('QBCore:Notify', src, 'Target player not found', 'error')
        return 
    end
    
    local custodyId = 'CUST-' .. os.time() .. '-' .. math.random(1000, 9999)
    
    MySQL.insert('INSERT INTO zmdt_custody (custody_id, citizenid, charges, arresting_officer, arresting_officer_name, custody_time, bail_amount, bond_amount, cell_number, cell_location, court_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        custodyId,
        targetPlayer.PlayerData.citizenid,
        json.encode(data.charges),
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        data.custody_time or Config.CustodySystem.default_custody_time,
        data.bail_amount or 0,
        data.bond_amount or 0,
        data.cell_number or math.random(1, #Config.CustodySystem.cell_locations),
        'LSPD Cell Block',
        os.date('%Y-%m-%d %H:%M:%S', os.time() + (2 * 24 * 60 * 60)) -- 2 days for court
    })
    
    -- Send webhook
    SendWebhook('custody', {
        title = 'Person In Custody',
        citizenid = targetPlayer.PlayerData.citizenid,
        citizen_name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
        charges = data.charges,
        custody_time = data.custody_time or Config.CustodySystem.default_custody_time,
        bail_amount = data.bail_amount or 0,
        officer = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        custody_id = custodyId
    })
    
    -- Log action
    LogAction(src, 'CREATE_CUSTODY', 'Put ' .. targetPlayer.PlayerData.citizenid .. ' in custody for ' .. (data.custody_time or Config.CustodySystem.default_custody_time) .. ' seconds')
    
    -- Update real-time
    UpdateRealTimeData('custody_created', {
        custody_id = custodyId,
        target_id = data.targetId,
        data = data
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Custody record created', 'success')
end)

-- Enhanced Dispatch System
RegisterNetEvent('zmdt:server:createDispatchCall', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local callId = 'CALL-' .. os.time() .. '-' .. math.random(1000, 9999)
    
    local coords = data.coords
    if type(coords) == 'table' and coords.x then
        coords = json.encode(coords)
    end
    
    MySQL.insert('INSERT INTO zmdt_dispatch_calls (call_id, title, description, location, coords, postal, caller, caller_phone, priority, type, category, created_by, created_by_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        callId,
        data.title,
        data.description,
        data.location or 'Unknown Location',
        coords,
        data.postal or '',
        data.caller or 'Anonymous',
        data.caller_phone or '',
        data.priority or 'medium',
        data.type or 'police',
        data.category or 'general',
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    -- Send to all authorized players
    local callData = {
        call_id = callId,
        title = data.title,
        description = data.description,
        location = data.location or 'Unknown Location',
        coords = json.decode(coords),
        postal = data.postal or '',
        caller = data.caller or 'Anonymous',
        caller_phone = data.caller_phone or '',
        priority = data.priority or 'medium',
        type = data.type or 'police',
        category = data.category or 'general',
        status = 'pending',
        created_by = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
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
        local TargetPlayer = QBCore.Functions.GetPlayer(playerId)
        if TargetPlayer then
            for _, job in pairs(targetJobs) do
                if TargetPlayer.PlayerData.job.name == job and TargetPlayer.PlayerData.job.onduty then
                    TriggerClientEvent('zmdt:dispatch:newCall', playerId, callData)
                    break
                end
            end
        end
    end
    
    -- Send webhook
    SendWebhook('dispatch', {
        title = 'New Dispatch Call',
        call_id = callId,
        title = data.title,
        location = data.location or 'Unknown Location',
        priority = data.priority or 'medium',
        type = data.type or 'police',
        caller = data.caller or 'Anonymous',
        created_by = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    -- Log action
    LogAction(src, 'CREATE_DISPATCH', 'Created dispatch call: ' .. callId)
    
    TriggerClientEvent('QBCore:Notify', src, 'Dispatch call created successfully', 'success')
end)

-- Boss Menu Functions
QBCore.Functions.CreateCallback('zmdt:server:getBossMenuData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    -- Check if player has boss permissions
    local jobRanks = MySQL.query.await('SELECT * FROM zmdt_job_ranks WHERE job_name = ? AND grade_level = ?', {
        Player.PlayerData.job.name,
        Player.PlayerData.job.grade.level
    })
    
    if not jobRanks or #jobRanks == 0 or not jobRanks[1].boss_actions then
        return cb({error = 'Insufficient permissions'})
    end
    
    local department = Player.PlayerData.job.name
    local accountData = MySQL.query.await('SELECT * FROM zmdt_department_accounts WHERE department = ?', {department})
    
    local data = {
        department = department,
        account_balance = accountData and #accountData > 0 and accountData[1].balance or 0,
        employees = GetDepartmentEmployees(department),
        recent_transactions = GetRecentTransactions(department, 30),
        statistics = GetDepartmentStatistics(department),
        fleet_vehicles = GetDepartmentFleet(department),
        armory_items = GetDepartmentArmory(department)
    }
    
    cb(data)
end)

-- Get department employees
function GetDepartmentEmployees(department)
    local employees = {}
    local players = MySQL.query.await([[
        SELECT p.citizenid, p.charinfo, p.job, j.grade_name, j.label as rank_label
        FROM players p
        LEFT JOIN zmdt_job_ranks j ON JSON_EXTRACT(p.job, '$.name') = j.job_name AND JSON_EXTRACT(p.job, '$.grade.level') = j.grade_level
        WHERE JSON_EXTRACT(p.job, '$.name') = ?
    ]], {department})
    
    for _, player in pairs(players) do
        local charinfo = json.decode(player.charinfo)
        local job = json.decode(player.job)
        
        table.insert(employees, {
            citizenid = player.citizenid,
            name = charinfo.firstname .. ' ' .. charinfo.lastname,
            rank = player.grade_name or job.grade.name,
            rank_label = player.rank_label or job.label,
            grade_level = job.grade.level,
            is_onduty = job.onduty or false,
            phone = charinfo.phone
        })
    end
    
    return employees
end

-- Get recent transactions
function GetRecentTransactions(department, days)
    local transactions = MySQL.query.await([[
        SELECT t.*, da.department
        FROM zmdt_transactions t
        JOIN zmdt_department_accounts da ON t.account_id = da.account_id
        WHERE da.department = ? AND t.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        ORDER BY t.created_at DESC
        LIMIT 50
    ]], {department, days})
    
    return transactions or {}
end

-- Get department statistics
function GetDepartmentStatistics(department)
    local stats = {
        total_incidents = 0,
        total_fines = 0,
        total_custody = 0,
        active_warrants = 0,
        total_fine_amount = 0,
        monthly_stats = {}
    }
    
    -- Get total incidents
    local incidents = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_incidents WHERE officer_id IN (SELECT citizenid FROM players WHERE JSON_EXTRACT(job, "$.name") = ?)', {department})
    if incidents and #incidents > 0 then
        stats.total_incidents = incidents[1].count
    end
    
    -- Get total fines
    local fines = MySQL.query.await('SELECT COUNT(*) as count, SUM(total_amount) as total FROM zmdt_fines WHERE issued_by IN (SELECT citizenid FROM players WHERE JSON_EXTRACT(job, "$.name") = ?)', {department})
    if fines and #fines > 0 then
        stats.total_fines = fines[1].count
        stats.total_fine_amount = fines[1].total or 0
    end
    
    -- Get total custody records
    local custody = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_custody WHERE arresting_officer IN (SELECT citizenid FROM players WHERE JSON_EXTRACT(job, "$.name") = ?)', {department})
    if custody and #fines > 0 then
        stats.total_custody = custody[1].count
    end
    
    -- Get active warrants
    local warrants = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_warrants WHERE status = "active" AND issued_by IN (SELECT citizenid FROM players WHERE JSON_EXTRACT(job, "$.name") = ?)', {department})
    if warrants and #warrants > 0 then
        stats.active_warrants = warrants[1].count
    end
    
    return stats
end

-- Process financial transaction
function ProcessFinancialTransaction(data)
    if not Config.GovernmentTax.enabled then return end
    
    local governmentTax = data.government_tax or 0
    local pdAmount = data.pd_amount or (data.amount - governmentTax)
    
    -- Update government account
    if governmentTax > 0 then
        MySQL.query('UPDATE zmdt_department_accounts SET balance = balance + ?, total_received = total_received + ?, last_transaction = NOW() WHERE account_id = ?', {
            governmentTax, governmentTax, Config.GovernmentTax.government_account
        })
        
        MySQL.insert('INSERT INTO zmdt_transactions (transaction_id, account_id, transaction_type, amount, balance_before, balance_after, reference_id, description, payer_id, tax_amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            'TXN-' .. os.time() .. '-' .. math.random(1000, 9999),
            Config.GovernmentTax.government_account,
            'government_tax',
            governmentTax,
            0, -- Will be calculated from balance query
            0, -- Will be calculated from balance query
            data.reference_id or data.fine_id,
            'Government tax from fine: ' .. (data.fine_id or 'Unknown'),
            data.payer_id or data.citizenid,
            governmentTax
        })
    end
    
    -- Update PD account
    if pdAmount > 0 then
        MySQL.query('UPDATE zmdt_department_accounts SET balance = balance + ?, total_received = total_received + ?, last_transaction = NOW() WHERE account_id = ?', {
            pdAmount, pdAmount, Config.GovernmentTax.pd_account
        })
        
        MySQL.insert('INSERT INTO zmdt_transactions (transaction_id, account_id, transaction_type, amount, balance_before, balance_after, reference_id, description, payer_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            'TXN-' .. os.time() .. '-' .. math.random(1000, 9999),
            Config.GovernmentTax.pd_account,
            data.type or 'fine_payment',
            pdAmount,
            0, -- Will be calculated from balance query
            0, -- Will be calculated from balance query
            data.reference_id or data.fine_id,
            'Fine payment: ' .. (data.fine_id or 'Unknown'),
            data.payer_id or data.citizenid
        })
    end
end

-- Get JG-Dealership Data
function GetDealershipData(plate)
    -- This function would integrate with JG-Dealership
    -- For now, return mock data
    return {
        purchase_date = '2023-01-15',
        purchase_price = 45000,
        dealership = 'Premium Motors',
        salesperson = 'John Dealer',
        warranty_expires = '2026-01-15',
        service_history = {
            {date = '2023-06-15', service = 'Oil Change', mileage = 15000},
            {date = '2023-12-15', service = 'Tire Rotation', mileage = 30000}
        }
    }
end

-- Real-time update system
function StartRealTimeUpdates()
    CreateThread(function()
        while true do
            Wait(Config.RealTimeUpdates.update_interval)
            
            local currentTime = GetGameTimer()
            if currentTime - lastUpdate >= Config.RealTimeUpdates.update_interval then
                ProcessUpdateQueue()
                lastUpdate = currentTime
            end
        end
    end)
end

function ProcessUpdateQueue()
    if #updateQueue == 0 then return end
    
    local updates = {}
    local maxUpdates = math.min(#updateQueue, Config.RealTimeUpdates.max_update_frequency)
    
    for i = 1, maxUpdates do
        table.insert(updates, table.remove(updateQueue, 1))
    end
    
    -- Send batched updates to all relevant players
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and HasMDTAccess(Player.PlayerData.job.name, Player.PlayerData.job.grade.level) then
            TriggerClientEvent('zmdt:client:realTimeUpdate', playerId, updates)
        end
    end
end

function UpdateRealTimeData(type, data)
    table.insert(updateQueue, {
        type = type,
        data = data,
        timestamp = os.time()
    })
end

-- Performance monitoring
function StartPerformanceMonitoring()
    CreateThread(function()
        while true do
            Wait(60000) -- Every minute
            
            local performanceData = {
                memory_usage = collectgarbage("count"),
                active_connections = #QBCore.Functions.GetPlayers(),
                database_queries = GetDatabaseQueryCount(),
                cache_hits = GetCacheHitRate(),
                update_queue_size = #updateQueue
            }
            
            if Config.Development.debug_mode then
                print('[^2Z-MDT^7] Performance Data:', json.encode(performanceData))
            end
        end
    end)
end

-- Utility Functions
function GetServerStats()
    return {
        total_citizens = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_citizens')[1].count,
        total_vehicles = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_vehicles')[1].count,
        total_incidents = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_incidents')[1].count,
        active_incidents = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_incidents WHERE status IN ("pending", "active")')[1].count,
        active_warrants = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_warrants WHERE status = "active"')[1].count,
        total_fines = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_fines')[1].count,
        unpaid_fines = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_fines WHERE status = "unpaid"')[1].count,
        active_custody = MySQL.query.await('SELECT COUNT(*) as count FROM zmdt_custody WHERE status IN ("booked", "held", "court")')[1].count
    }
end

function GetOnlinePlayersData()
    local onlineData = {}
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            table.insert(onlineData, {
                server_id = playerId,
                citizenid = Player.PlayerData.citizenid,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                job = Player.PlayerData.job.name,
                grade = Player.PlayerData.job.grade.name,
                is_onduty = Player.PlayerData.job.onduty or false,
                coords = GetEntityCoords(GetPlayerPed(playerId))
            })
        end
    end
    return onlineData
end

function HasMDTAccess(jobName, gradeLevel)
    if not Config.AuthorizedJobs[jobName] then return false end
    return true
end

function GetPlayerPermissions(job, grade)
    if Config.AuthorizedJobs[job] then
        return Config.AuthorizedJobs[job].permissions or {}
    end
    return {}
end

-- Enhanced Discord webhook system
function SendWebhook(type, data)
    if not Config.Webhooks[type] or Config.Webhooks[type] == '' then return end
    
    local embed = {
        {
            title = data.title,
            description = data.description or '',
            color = Config.DiscordBot.embed_colors[data.severity or 'info'] or 3447003,
            fields = {},
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            footer = {
                text = Config.DiscordBot.footer_text or 'Z-MDT System',
                icon_url = Config.DiscordBot.avatar_url or ''
            }
        }
    }
    
    -- Add fields based on data
    for k, v in pairs(data) do
        if k ~= 'title' and k ~= 'description' and k ~= 'severity' then
            table.insert(embed[1].fields, {
                name = k:gsub('_', ' '):gsub('^%l', string.upper),
                value = tostring(v),
                inline = true
            })
        end
    end
    
    PerformHttpRequest(Config.Webhooks[type], function(err, text, headers) 
        if err ~= 200 then
            print('[^1Z-MDT^7] Webhook error for ' .. type .. ': ' .. err)
        end
    end, 'POST', json.encode({
        username = Config.DiscordBot.bot_name or 'Z-MDT Bot',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Enhanced audit logging
function LogAction(source, action, details)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local jobRanks = MySQL.query.await('SELECT * FROM zmdt_job_ranks WHERE job_name = ? AND grade_level = ?', {
        Player.PlayerData.job.name,
        Player.PlayerData.job.grade.level
    })
    
    MySQL.insert('INSERT INTO zmdt_audit_logs (action, user_id, user_name, user_job, user_grade, details, ip_address, action_category, severity, success) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        action,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.job.name,
        Player.PlayerData.job.grade.level,
        details,
        GetPlayerEndpoint(source) or 'Unknown',
        GetActionCategory(action),
        GetActionSeverity(action),
        true
    })
end

function GetActionCategory(action)
    if action:find('INCIDENT') then return 'incident_management' end
    if action:find('FINE') then return 'fine_management' end
    if action:find('WARRANT') then return 'warrant_management' end
    if action:find('CUSTODY') then return 'custody_management' end
    if action:find('DISPATCH') then return 'dispatch_management' end
    if action:find('EVIDENCE') then return 'evidence_management' end
    if action:find('SEARCH') then return 'search_operations' end
    if action:find('BOSS') then return 'boss_actions' end
    return 'general'
end

function GetActionSeverity(action)
    if action:find('CREATE') or action:find('UPDATE') then return 'info' end
    if action:find('DELETE') or action:find('CANCEL') then return 'warning' end
    if action:find('ERROR') or action:find('FAIL') then return 'error' end
    if action:find('CRITICAL') or action:find('EMERGENCY') then return 'critical' end
    return 'info'
end

-- Commands
QBCore.Commands.Add('mdt', 'Open MDT Tablet', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local hasTablet = Player.Functions.GetItemByName(Config.TabletItem)
    if not hasTablet then
        TriggerClientEvent('QBCore:Notify', source, 'You need an MDT tablet', 'error')
        return
    end
    
    TriggerClientEvent('zmdt:client:useTablet', source)
end)

QBCore.Commands.Add('bossmenu', 'Open Boss Menu', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if player has boss permissions
    local jobRanks = MySQL.query.await('SELECT * FROM zmdt_job_ranks WHERE job_name = ? AND grade_level = ?', {
        Player.PlayerData.job.name,
        Player.PlayerData.job.grade.level
    })
    
    if not jobRanks or #jobRanks == 0 or not jobRanks[1].boss_actions then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have access to the boss menu', 'error')
        return
    end
    
    TriggerClientEvent('zmdt:client:openBossMenu', source)
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
    
    -- Send real-time update
    UpdateRealTimeData('player_joined', {
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        job = Player.PlayerData.job.name,
        grade = Player.PlayerData.job.grade.name
    })
end)

-- Player Dropped
AddEventHandler('playerDropped', function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        UpdateRealTimeData('player_left', {
            citizenid = Player.PlayerData.citizenid,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            reason = reason
        })
    end
end)

-- Exports
exports('LogAction', LogAction)
exports('SendWebhook', SendWebhook)
exports('ProcessFinancialTransaction', ProcessFinancialTransaction)
exports('UpdateRealTimeData', UpdateRealTimeData)