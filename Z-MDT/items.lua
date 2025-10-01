-- Z-MDT Tablet Item Configuration
-- Add this to your qb-core/shared/items.lua or create a new file and import it

QBCore = exports['qb-core']:GetCoreObject()

-- Z-MDT Tablet Item
QBCore.Functions.CreateUseableItem('zmdt_tablet', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check job access
    local hasAccess = false
    if Config.AuthorizedJobs[Player.PlayerData.job.name] then
        for _, grade in pairs(Config.AuthorizedJobs[Player.job.grade.level].grades) do
            if Player.PlayerData.job.grade.level == grade then
                hasAccess = true
                break
            end
        end
    end
    
    if not hasAccess then
        TriggerClientEvent('QBCore:Notify', source, 'You do not have access to the MDT', 'error')
        return
    end
    
    -- Open MDT
    TriggerClientEvent('zmdt:client:openTablet', source)
end)

-- Add tablet item to QBCore if it doesn't exist
CreateThread(function()
    while not QBCore do
        Wait(100)
    end
    
    -- Check if item exists, if not add it
    local items = exports['qb-core']:GetItems()
    if not items['zmdt_tablet'] then
        -- You can add the item to your qb-core/shared/items.lua instead
        -- This is just a fallback
        print("^3[Z-MDT] ^7Please add the following to your qb-core/shared/items.lua:")
        print([[
            ['zmdt_tablet'] = {
                name = 'zmdt_tablet',
                label = 'Police Tablet',
                weight = 500,
                type = 'item',
                image = 'tablet.png',
                unique = true,
                useable = true,
                description = 'A police tablet for accessing the MDT system',
                shouldClose = true,
                combinable = nil
            },
        ]])
    end
end)