-- Z-MDT Tablet Item Definition

-- For ox_inventory
if GetResourceState('ox_inventory') ~= 'missing' then
    -- Police Tablet
    exports('ox_inventory'):RegisterItem('zmdt_tablet', {
        label = 'Police Tablet',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Mobile Data Terminal for law enforcement',
        client = {
            image = 'zmdt_tablet',
            usetime = 1000,
            export = 'Z-MDT.useTablet'
        }
    })
    
    -- Medical Tablet
    exports('ox_inventory'):RegisterItem('zmdt_medical_tablet', {
        label = 'Medical Tablet',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Mobile Data Terminal for medical personnel',
        client = {
            image = 'zmdt_medical_tablet',
            usetime = 1000,
            export = 'Z-MDT.useMedicalTablet'
        }
    })
end

-- For qb-inventory
if Config.Integrations.Inventory == 'qb-inventory' then
    -- Add items to QBCore shared items
    QBCore.Functions.AddItem('zmdt_tablet', {
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
    })
    
    QBCore.Functions.AddItem('zmdt_medical_tablet', {
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
    })
end