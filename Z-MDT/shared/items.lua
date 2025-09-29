-- Z-MDT Tablet Item Definition
local QBCore = exports['qb-core']:GetCoreObject()

-- For ox_inventory
if GetResourceState('ox_inventory') ~= 'missing' then
    -- Register items via ox_inventory's metadata (if needed)
    -- Item registration is usually done in ox_inventory's config, not via script
    -- If you need to register useable items, do it in client/main.lua or medical.lua
end

-- For qb-inventory: Add items to shared items table (not via AddItem)
if Config.Integrations.Inventory == 'qb-inventory' then
    -- Add items to QBCore.Shared.Items
    QBCore.Shared.Items['zmdt_tablet'] = {
        name = 'zmdt_tablet',
        label = 'Police Tablet',
        weight = 1000,
        type = 'item',
        image = 'zmdt_tablet.png',
        unique = true,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'Mobile Data Terminal for law enforcement'
    }
    QBCore.Shared.Items['zmdt_medical_tablet'] = {
        name = 'zmdt_medical_tablet',
        label = 'Medical Tablet',
        weight = 1000,
        type = 'item',
        image = 'zmdt_tablet.png',
        unique = true,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'Mobile Data Terminal for medical personnel'
    }
end