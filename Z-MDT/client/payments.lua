-- Z-MDT Fine Payment System

local QBCore = exports['qb-core']:GetCoreObject()
local paymentBlips = {}
local activePaymentLocations = {}

-- Initialize payment locations
CreateThread(function()
    -- Create blips for static payment locations
    for _, location in pairs(Config.FinePaymentLocations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, Config.Blips.fine_payment.sprite)
        SetBlipColour(blip, Config.Blips.fine_payment.color)
        SetBlipScale(blip, Config.Blips.fine_payment.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Blips.fine_payment.label)
        EndTextCommandSetBlipName(blip)
        
        table.insert(paymentBlips, blip)
    end
    
    -- Create payment markers and interaction zones
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000
        local isNearPayment = false
        
        -- Check static payment locations
        for _, location in pairs(Config.FinePaymentLocations) do
            local distance = #(playerCoords - vector3(location.coords.x, location.coords.y, location.coords.z))
            
            if distance < 10.0 then
                sleep = 0
                isNearPayment = true
                
                -- Draw marker
                DrawMarker(1, location.coords.x, location.coords.y, location.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                
                -- Check for interaction
                if distance < 1.5 then
                    -- Display help text
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to pay fines')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    -- Check for key press
                    if IsControlJustReleased(0, 38) then -- E key
                        OpenFinePaymentMenu()
                    end
                end
            end
        end
        
        -- Check dynamic payment locations
        for fineId, location in pairs(activePaymentLocations) do
            local distance = #(playerCoords - vector3(location.x, location.y, location.z))
            
            if distance < 10.0 then
                sleep = 0
                isNearPayment = true
                
                -- Draw marker
                DrawMarker(1, location.x, location.y, location.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                
                -- Check for interaction
                if distance < 1.5 then
                    -- Display help text
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to pay fine #' .. fineId)
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    -- Check for key press
                    if IsControlJustReleased(0, 38) then -- E key
                        PaySpecificFine(fineId)
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Open fine payment menu
function OpenFinePaymentMenu()
    QBCore.Functions.TriggerCallback('zmdt:server:getPlayerFines', function(result)
        if result.success then
            if #result.data == 0 then
                QBCore.Functions.Notify('You have no unpaid fines', 'error')
                return
            end
            
            -- Create menu options
            local menuOptions = {}
            
            for _, fine in pairs(result.data) do
                table.insert(menuOptions, {
                    title = 'Fine #' .. fine.fine_id,
                    description = 'Amount: £' .. fine.total_amount .. ' | Due: ' .. fine.due_date,
                    onSelect = function()
                        TriggerServerEvent('zmdt:server:payFine', fine.fine_id)
                    end
                })
            end
            
            -- Show menu using ox_lib
            if GetResourceState('ox_lib') ~= 'missing' then
                exports['ox_lib']:registerContext({
                    id = 'zmdt_fine_payment',
                    title = 'Pay Fines',
                    options = menuOptions
                })
                exports['ox_lib']:showContext('zmdt_fine_payment')
            else
                -- Fallback for non-ox_lib servers
                local fineId = result.data[1].fine_id
                QBCore.Functions.Notify('Paying fine #' .. fineId, 'primary')
                TriggerServerEvent('zmdt:server:payFine', fineId)
            end
        else
            QBCore.Functions.Notify(result.message, 'error')
        end
    end)
end

-- Pay a specific fine
function PaySpecificFine(fineId)
    TriggerServerEvent('zmdt:server:payFine', fineId)
end

-- Add dynamic payment location
RegisterNetEvent('zmdt:client:createFineBlip', function(coords, fineId)
    -- Create blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Blips.fine_payment.sprite)
    SetBlipColour(blip, Config.Blips.fine_payment.color)
    SetBlipScale(blip, Config.Blips.fine_payment.scale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Pay Fine #' .. fineId)
    EndTextCommandSetBlipName(blip)
    
    -- Store blip and location
    paymentBlips[fineId] = blip
    activePaymentLocations[fineId] = coords
    
    -- Notify player
    QBCore.Functions.Notify('Fine payment location has been marked on your map', 'primary')
end)

-- Remove dynamic payment location
RegisterNetEvent('zmdt:client:removeFineBlip', function(fineId)
    if paymentBlips[fineId] then
        RemoveBlip(paymentBlips[fineId])
        paymentBlips[fineId] = nil
        activePaymentLocations[fineId] = nil
    end
end)

-- Get player's unpaid fines (server-side callback moved to server files)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Remove all blips
        for _, blip in pairs(paymentBlips) do
            RemoveBlip(blip)
        end
    end
end)