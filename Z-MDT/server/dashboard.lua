local Config = require('Config') -- Assuming there's a Config module
local updateInterval = Config.UpdateInterval or 5000 -- Default to 5000 ms if not set

local function collectData()
    while true do
        Citizen.Wait(updateInterval)

        local citizenCount = MySQL.Sync.fetchScalar("SELECT COUNT(*) FROM citizens")
        local vehicleCount = MySQL.Sync.fetchScalar("SELECT COUNT(*) FROM vehicles")
        local incidentCount = MySQL.Sync.fetchScalar("SELECT COUNT(*) FROM incidents")
        local warrantCount = MySQL.Sync.fetchScalar("SELECT COUNT(*) FROM warrants")

        local recentActivity = MySQL.Sync.fetchAll("SELECT * FROM activity ORDER BY time DESC LIMIT 10")
        
        -- Broadcast to all MDT clients
        TriggerClientEvent('zmdt:client:updateDashboard', -1, {
            citizenCount = citizenCount,
            vehicleCount = vehicleCount,
            incidentCount = incidentCount,
            warrantCount = warrantCount
        })
        
        for _, activity in ipairs(recentActivity) do
            TriggerClientEvent('zmdt:client:newActivity', -1, activity)
        end
    end
end

-- Check if the job is allowed to receive updates
local function isJobAllowed(job)
    local allowedJobs = Config.AllowedJobs
    return allowedJobs[job] or false
end

-- Auto-detect the framework
if Config.Framework == 'QBcore' then
    -- QBcore specific logic
elseif Config.Framework == 'qbox' then
    -- qbox specific logic
end

-- Start the data collection
CollectData()