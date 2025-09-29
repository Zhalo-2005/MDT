local QBCore = exports['qb-core']:GetCoreObject()
-- Z-MDT Department Management System

-- Get department accounts
QBCore.Functions.CreateCallback('zmdt:server:getDepartmentAccounts', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({success = false, message = 'Player not found'}) end
    
    -- Check if player has admin permission or is a department manager
    local isAdmin = IsPlayerAdmin(Player)
    local isDepartmentManager = IsDepartmentManager(Player)
    
    if not isAdmin and not isDepartmentManager then
        return cb({success = false, message = 'You do not have permission to view department accounts'})
    end
    
    -- Get department accounts
    local accounts = MySQL.query.await('SELECT * FROM zmdt_department_accounts')
    
    -- Get recent transactions
    local transactions = MySQL.query.await('SELECT * FROM zmdt_department_transactions ORDER BY created_at DESC LIMIT 50')
    
    -- Format department accounts with labels from config
    local formattedAccounts = {}
    for _, account in pairs(accounts) do
        local dept = account.department
        local label = dept
        
        if Config.DepartmentAccounts[dept] then
            label = Config.DepartmentAccounts[dept].label
        end
        
        table.insert(formattedAccounts, {
            department = dept,
            label = label,
            balance = account.balance,
            updated_at = account.updated_at
        })
    end
    
    cb({success = true, data = {accounts = formattedAccounts, transactions = transactions}})
end)

-- Add funds to department account
RegisterNetEvent('zmdt:server:addDepartmentFunds', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player has admin permission or is a department manager
    local isAdmin = IsPlayerAdmin(Player)
    local isDepartmentManager = IsDepartmentManager(Player, data.department)
    
    if not isAdmin and not isDepartmentManager then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to add department funds', 'error')
        return
    end
    
    -- Validate amount
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid amount', 'error')
        return
    end
    
    -- Update department account
    MySQL.update('UPDATE zmdt_department_accounts SET balance = balance + ? WHERE department = ?', {amount, data.department})
    
    -- Add transaction record
    MySQL.insert('INSERT INTO zmdt_department_transactions (department, amount, type, description, created_by, created_by_name) VALUES (?, ?, ?, ?, ?, ?)', {
        data.department,
        amount,
        'deposit',
        data.description or 'Funds added',
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    -- Log action
    LogAction(src, 'ADD_DEPARTMENT_FUNDS', 'Added £' .. amount .. ' to ' .. data.department .. ' department')
    
    -- Notify client
    TriggerClientEvent('QBCore:Notify', src, 'Added £' .. amount .. ' to department funds', 'success')
end)

-- Remove funds from department account
RegisterNetEvent('zmdt:server:removeDepartmentFunds', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player has admin permission or is a department manager
    local isAdmin = IsPlayerAdmin(Player)
    local isDepartmentManager = IsDepartmentManager(Player, data.department)
    
    if not isAdmin and not isDepartmentManager then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to remove department funds', 'error')
        return
    end
    
    -- Validate amount
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid amount', 'error')
        return
    end
    
    -- Check if department has enough funds
    local account = MySQL.query.await('SELECT balance FROM zmdt_department_accounts WHERE department = ?', {data.department})
    
    if not account or #account == 0 or account[1].balance < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Department does not have enough funds', 'error')
        return
    end
    
    -- Update department account
    MySQL.update('UPDATE zmdt_department_accounts SET balance = balance - ? WHERE department = ?', {amount, data.department})
    
    -- Add transaction record
    MySQL.insert('INSERT INTO zmdt_department_transactions (department, amount, type, description, created_by, created_by_name) VALUES (?, ?, ?, ?, ?, ?)', {
        data.department,
        amount,
        'withdrawal',
        data.description or 'Funds withdrawn',
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    -- Log action
    LogAction(src, 'REMOVE_DEPARTMENT_FUNDS', 'Removed £' .. amount .. ' from ' .. data.department .. ' department')
    
    -- Notify client
    TriggerClientEvent('QBCore:Notify', src, 'Removed £' .. amount .. ' from department funds', 'success')
end)

-- Transfer funds between department accounts
RegisterNetEvent('zmdt:server:transferDepartmentFunds', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player has admin permission or is a department manager
    local isAdmin = IsPlayerAdmin(Player)
    local isSourceManager = IsDepartmentManager(Player, data.source_department)
    
    if not isAdmin and not isSourceManager then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to transfer department funds', 'error')
        return
    end
    
    -- Validate amount
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid amount', 'error')
        return
    end
    
    -- Check if source department has enough funds
    local sourceAccount = MySQL.query.await('SELECT balance FROM zmdt_department_accounts WHERE department = ?', {data.source_department})
    
    if not sourceAccount or #sourceAccount == 0 or sourceAccount[1].balance < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Source department does not have enough funds', 'error')
        return
    end
    
    -- Check if target department exists
    local targetAccount = MySQL.query.await('SELECT balance FROM zmdt_department_accounts WHERE department = ?', {data.target_department})
    
    if not targetAccount or #targetAccount == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Target department does not exist', 'error')
        return
    end
    
    -- Update department accounts
    MySQL.update('UPDATE zmdt_department_accounts SET balance = balance - ? WHERE department = ?', {amount, data.source_department})
    MySQL.update('UPDATE zmdt_department_accounts SET balance = balance + ? WHERE department = ?', {amount, data.target_department})
    
    -- Add transaction records
    MySQL.insert('INSERT INTO zmdt_department_transactions (department, amount, type, description, created_by, created_by_name) VALUES (?, ?, ?, ?, ?, ?)', {
        data.source_department,
        amount,
        'withdrawal',
        'Transfer to ' .. data.target_department .. (data.description and ': ' .. data.description or ''),
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    MySQL.insert('INSERT INTO zmdt_department_transactions (department, amount, type, description, created_by, created_by_name) VALUES (?, ?, ?, ?, ?, ?)', {
        data.target_department,
        amount,
        'deposit',
        'Transfer from ' .. data.source_department .. (data.description and ': ' .. data.description or ''),
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    -- Log action
    LogAction(src, 'TRANSFER_DEPARTMENT_FUNDS', 'Transferred £' .. amount .. ' from ' .. data.source_department .. ' to ' .. data.target_department)
    
    -- Notify client
    TriggerClientEvent('QBCore:Notify', src, 'Transferred £' .. amount .. ' between departments', 'success')
end)

-- Get department transactions
QBCore.Functions.CreateCallback('zmdt:server:getDepartmentTransactions', function(source, cb, department)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({success = false, message = 'Player not found'}) end
    
    -- Check if player has admin permission or is a department manager
    local isAdmin = IsPlayerAdmin(Player)
    local isDepartmentManager = IsDepartmentManager(Player, department)
    
    if not isAdmin and not isDepartmentManager then
        return cb({success = false, message = 'You do not have permission to view department transactions'})
    end
    
    -- Get department transactions
    local transactions = MySQL.query.await('SELECT * FROM zmdt_department_transactions WHERE department = ? ORDER BY created_at DESC LIMIT 100', {department})
    
    cb({success = true, data = transactions or {}})
end)

-- Check if player is a department manager
function IsDepartmentManager(Player, department)
    if not Player then return false end
    
    local job = Player.PlayerData.job.name
    local grade = Player.PlayerData.job.grade.level
    
    -- If department is specified, check if player's job matches
    if department and job ~= department then
        return false
    end
    
    -- Check if player is a high-ranking officer
    if Config.AuthorizedJobs[job] then
        local highestGrade = 0
        for _, authorizedGrade in pairs(Config.AuthorizedJobs[job].grades) do
            if authorizedGrade > highestGrade then
                highestGrade = authorizedGrade
            end
        end
        
        -- Department managers are typically the highest or second-highest rank
        if grade >= highestGrade - 1 then
            return true
        end
    end
    
    return false
end

-- Export functions
exports('IsDepartmentManager', IsDepartmentManager)