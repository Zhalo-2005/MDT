-- Z-MDT Audit Logging System

-- Log an action to the audit log
function LogAction(source, action, details)
    if not Config.AuditLog.enabled then return end
    
    -- Check if action should be logged
    local shouldLog = false
    for _, logAction in pairs(Config.AuditLog.log_actions) do
        if logAction == action then
            shouldLog = true
            break
        end
    end
    
    if not shouldLog then return end
    
    -- Get player information
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local userId = Player.PlayerData.citizenid
    local userName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    -- Get IP address if available
    local ipAddress = GetPlayerEndpoint(source) or 'Unknown'
    
    -- Insert audit log
    MySQL.insert('INSERT INTO zmdt_audit_logs (action, user_id, user_name, details, ip_address) VALUES (?, ?, ?, ?, ?)', {
        action,
        userId,
        userName,
        details,
        ipAddress
    })
end

-- Get audit logs
QBCore.Functions.CreateCallback('zmdt:server:getAuditLogs', function(source, cb, filter)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({success = false, message = 'Player not found'}) end
    
    -- Check if player has admin permission
    local isAdmin = IsPlayerAdmin(Player)
    
    if not isAdmin then
        return cb({success = false, message = 'You do not have permission to view audit logs'})
    end
    
    -- Build query based on filter
    local query = 'SELECT * FROM zmdt_audit_logs'
    local params = {}
    
    if filter then
        local whereClause = {}
        
        if filter.action then
            table.insert(whereClause, 'action = ?')
            table.insert(params, filter.action)
        end
        
        if filter.user_id then
            table.insert(whereClause, 'user_id = ?')
            table.insert(params, filter.user_id)
        end
        
        if filter.start_date then
            table.insert(whereClause, 'created_at >= ?')
            table.insert(params, filter.start_date)
        end
        
        if filter.end_date then
            table.insert(whereClause, 'created_at <= ?')
            table.insert(params, filter.end_date)
        end
        
        if #whereClause > 0 then
            query = query .. ' WHERE ' .. table.concat(whereClause, ' AND ')
        end
    end
    
    query = query .. ' ORDER BY created_at DESC LIMIT 500'
    
    -- Get audit logs
    local logs = MySQL.query.await(query, params)
    
    cb({success = true, data = logs or {}})
end)

-- Clean up old audit logs
function CleanupAuditLogs()
    if not Config.AuditLog.enabled then return end
    
    local retentionDays = Config.AuditLog.retention_days or 30
    
    MySQL.query('DELETE FROM zmdt_audit_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)', {retentionDays})
end

-- Run cleanup on resource start
CreateThread(function()
    Wait(10000) -- Wait 10 seconds after resource start
    CleanupAuditLogs()
    
    -- Schedule cleanup to run daily
    while true do
        Wait(24 * 60 * 60 * 1000) -- 24 hours
        CleanupAuditLogs()
    end
end)

-- Check if player is an admin
function IsPlayerAdmin(Player)
    if not Player then return false end
    
    -- Check if player is a QBCore admin
    local group = Player.PlayerData.group
    if group == 'admin' or group == 'god' or group == 'superadmin' then
        return true
    end
    
    -- Check if player has ace permission
    local source = Player.PlayerData.source
    if IsPlayerAceAllowed(source, 'command.zmdt_admin') then
        return true
    end
    
    return false
end

-- Export the LogAction function
exports('LogAction', LogAction)