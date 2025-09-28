local activeDispatches = {}
local dispatchBlips = {}

-- Custom Dispatch System
RegisterNetEvent('zmdt:dispatch:newCall', function(callData)
    -- Create blip
    local blip = AddBlipForCoord(callData.coords.x, callData.coords.y, callData.coords.z)
    
    local sprite = 161
    local color = 1
    
    if callData.type == 'medical' then
        sprite = 153
        color = 1
    elseif callData.type == 'fire' then
        sprite = 436
        color = 1
    end
    
    if callData.priority == 'critical' then
        color = 1 -- Red
    elseif callData.priority == 'high' then
        color = 17 -- Orange
    elseif callData.priority == 'medium' then
        color = 5 -- Yellow
    else
        color = 2 -- Green
    end
    
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(callData.title)
    EndTextCommandSetBlipName(blip)
    
    -- Flash blip for high priority calls
    if callData.priority == 'critical' or callData.priority == 'high' then
        SetBlipFlashes(blip, true)
    end
    
    dispatchBlips[callData.call_id] = blip
    activeDispatches[callData.call_id] = callData
    
    -- Show notification
    local priorityText = string.upper(callData.priority)
    QBCore.Functions.Notify('New ' .. priorityText .. ' Priority Call: ' .. callData.title, 'primary', 8000)
    
    -- Play sound based on priority
    if callData.priority == 'critical' then
        PlaySoundFrontend(-1, 'police_notification', 'DLC_AS_VNT_Sounds', true)
    elseif callData.priority == 'high' then
        PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
    end
    
    -- Send to MDT if open
    if isTabletOpen then
        SendNUIMessage({
            action = 'newDispatchCall',
            data = callData
        })
    end
end)

RegisterNetEvent('zmdt:dispatch:updateCall', function(callId, updateData)
    if activeDispatches[callId] then
        for k, v in pairs(updateData) do
            activeDispatches[callId][k] = v
        end
        
        -- Update MDT if open
        if isTabletOpen then
            SendNUIMessage({
                action = 'updateDispatchCall',
                data = {
                    callId = callId,
                    updateData = updateData
                }
            })
        end
        
        -- Remove blip if call is closed
        if updateData.status == 'closed' and dispatchBlips[callId] then
            RemoveBlip(dispatchBlips[callId])
            dispatchBlips[callId] = nil
            activeDispatches[callId] = nil
        end
    end
end)

-- NUI Callbacks for Dispatch
RegisterNUICallback('acceptDispatch', function(data, cb)
    TriggerServerEvent('zmdt:server:acceptDispatch', data.callId)
    cb('ok')
end)

RegisterNUICallback('closeDispatch', function(data, cb)
    TriggerServerEvent('zmdt:server:closeDispatch', data.callId)
    cb('ok')
end)

RegisterNUICallback('setGPS', function(data, cb)
    if activeDispatches[data.callId] then
        local coords = activeDispatches[data.callId].coords
        SetNewWaypoint(coords.x, coords.y)
        QBCore.Functions.Notify('GPS set to dispatch location', 'success')
    end
    cb('ok')
end)

-- Emergency Services Integration
function CreateDispatchCall(title, description, coords, callType, priority)
    local callData = {
        title = title,
        description = description,
        coords = coords,
        type = callType or 'police',
        priority = priority or 'medium',
        caller = 'System'
    }
    
    TriggerServerEvent('zmdt:server:createDispatchCall', callData)
end

-- Export for other resources
exports('CreateDispatchCall', CreateDispatchCall)

-- Integration with other dispatch systems
if Config.Integrations.Dispatch == 'ps-dispatch' then
    -- PS-Dispatch integration
    RegisterNetEvent('ps-dispatch:client:notify', function(dispatchData)
        -- Convert PS-Dispatch format to Z-MDT format
        local callData = {
            title = dispatchData.message,
            description = dispatchData.dispatchMessage or dispatchData.message,
            coords = dispatchData.coords,
            type = dispatchData.job and dispatchData.job[1] or 'police',
            priority = dispatchData.priority or 'medium',
            caller = dispatchData.caller or 'Anonymous'
        }
        
        TriggerEvent('zmdt:dispatch:newCall', callData)
    end)
elseif Config.Integrations.Dispatch == 'rcore' then
    -- rCore Dispatch integration
    RegisterNetEvent('rcore_dispatch:server:sendAlert', function(alertData)
        local callData = {
            title = alertData.displayCode .. ' - ' .. alertData.description,
            description = alertData.description,
            coords = alertData.coords,
            type = alertData.job or 'police',
            priority = alertData.priority or 'medium',
            caller = alertData.caller or 'Anonymous'
        }
        
        TriggerEvent('zmdt:dispatch:newCall', callData)
    end)
end
