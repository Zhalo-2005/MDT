-- Z-MDT Client Script
local QBCore = exports['qb-core']:GetCoreObject()
local isOpen = false
local tabletProp = nil
local tabletModel = `prop_cs_tablet`

-- Initialize the MDT
CreateThread(function()
    while not QBCore do
        Wait(100)
    end
    
    -- Register tablet item
    RegisterTabletItem()
    
    -- Register key mapping
    RegisterKeyMapping('zmdt', 'Open Z-MDT Tablet', 'keyboard', Config.DefaultKey or 'F6')
    RegisterCommand('zmdt', function()
        OpenMDT()
    end, false)
end)

-- Register tablet item
function RegisterTabletItem()
    if Config.UseTabletItem then
        QBCore.Functions.CreateUseableItem('zmdt_tablet', function(source, item)
            TriggerClientEvent('zmdt:client:openTablet', source)
        end)
    end
end

-- Open MDT
function OpenMDT()
    if isOpen then return end
    
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return end
    
    -- Check job access
    local hasAccess = false
    if Config.AuthorizedJobs[Player.job.name] then
        for _, grade in pairs(Config.AuthorizedJobs[Player.job.name].grades) do
            if Player.job.grade.level == grade then
                hasAccess = true
                break
            end
        end
    end
    
    if not hasAccess then
        QBCore.Functions.Notify('You do not have access to the MDT', 'error')
        return
    end
    
    -- Create tablet prop
    CreateTabletProp()
    
    -- Open NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open',
        job = Player.job.name,
        grade = Player.job.grade.level,
        playerData = {
            name = Player.charinfo.firstname .. ' ' .. Player.charinfo.lastname,
            callsign = Player.metadata.callsign or 'N/A',
            department = Player.job.label
        }
    })
    
    isOpen = true
    
    -- Trigger server event
    TriggerServerEvent('zmdt:server:mdtOpened')
end

-- Close MDT
function CloseMDT()
    if not isOpen then return end
    
    -- Close NUI
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
    
    -- Delete tablet prop
    DeleteTabletProp()
    
    isOpen = false
    
    -- Trigger server event
    TriggerServerEvent('zmdt:server:mdtClosed')
end

-- Create tablet prop
function CreateTabletProp()
    if tabletProp then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    RequestModel(tabletModel)
    while not HasModelLoaded(tabletModel) do
        Wait(10)
    end
    
    tabletProp = CreateObject(tabletModel, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(tabletProp, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.03, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    -- Animation
    RequestAnimDict('anim@heists@box_carry@')
    while not HasAnimDictLoaded('anim@heists@box_carry@') do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
end

-- Delete tablet prop
function DeleteTabletProp()
    if tabletProp then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
    
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    RemoveAnimDict('anim@heists@box_carry@')
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('getPlayerData', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getPlayerData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('searchCitizen', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:searchCitizen', function(result)
        cb(result)
    end, data.query)
end)

RegisterNUICallback('getCitizenDetails', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getCitizenDetails', function(result)
        cb(result)
    end, data.citizenid)
end)

RegisterNUICallback('getCitizenVehicles', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getCitizenVehicles', function(result)
        cb(result)
    end, data.citizenid)
end)

RegisterNUICallback('getCitizenFines', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getCitizenFines', function(result)
        cb(result)
    end, data.citizenid)
end)

RegisterNUICallback('getAllFines', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getAllFines', function(result)
        cb(result)
    end, data.filter)
end)

RegisterNUICallback('issueFine', function(data, cb)
    TriggerServerEvent('zmdt:server:issueFine', data)
    cb('ok')
end)

RegisterNUICallback('payFine', function(data, cb)
    TriggerServerEvent('zmdt:server:payFine', data.fineId)
    cb('ok')
end)

RegisterNUICallback('cancelFine', function(data, cb)
    TriggerServerEvent('zmdt:server:cancelFine', data.fineId)
    cb('ok')
end)

RegisterNUICallback('searchVehicle', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:searchVehicle', function(result)
        cb(result)
    end, data.plate)
end)

RegisterNUICallback('getVehicleDetails', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getVehicleDetails', function(result)
        cb(result)
    end, data.plate)
end)

RegisterNUICallback('createIncident', function(data, cb)
    TriggerServerEvent('zmdt:server:createIncident', data)
    cb('ok')
end)

RegisterNUICallback('getIncidents', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getIncidents', function(result)
        cb(result)
    end, data.filter)
end)

RegisterNUICallback('getIncidentDetails', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getIncidentDetails', function(result)
        cb(result)
    end, data.id)
end)

RegisterNUICallback('updateIncident', function(data, cb)
    TriggerServerEvent('zmdt:server:updateIncident', data)
    cb('ok')
end)

RegisterNUICallback('createBOLO', function(data, cb)
    TriggerServerEvent('zmdt:server:createBOLO', data)
    cb('ok')
end)

RegisterNUICallback('getBOLOs', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getBOLOs', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('deleteBOLO', function(data, cb)
    TriggerServerEvent('zmdt:server:deleteBOLO', data.id)
    cb('ok')
end)

RegisterNUICallback('jailPlayer', function(data, cb)
    TriggerServerEvent('zmdt:server:jailPlayer', data)
    cb('ok')
end)

RegisterNUICallback('releasePlayer', function(data, cb)
    TriggerServerEvent('zmdt:server:releasePlayer', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('getJailStatus', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getJailStatus', function(result)
        cb(result)
    end, data.citizenid)
end)

RegisterNUICallback('getAllJailedPlayers', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getAllJailedPlayers', function(result)
        cb(result)
    end)
end)

-- Events
RegisterNetEvent('zmdt:client:openTablet', function()
    OpenMDT()
end)

RegisterNetEvent('zmdt:client:createFineBlip', function(coords, fineId)
    -- Create blip for fine payment location
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 408)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Fine Payment: " .. fineId)
    EndTextCommandSetBlipName(blip)
    
    -- Store blip for removal later
    if not Config.ActiveFineBlips then
        Config.ActiveFineBlips = {}
    end
    Config.ActiveFineBlips[fineId] = blip
end)

RegisterNetEvent('zmdt:client:removeFineBlip', function(fineId)
    if Config.ActiveFineBlips and Config.ActiveFineBlips[fineId] then
        RemoveBlip(Config.ActiveFineBlips[fineId])
        Config.ActiveFineBlips[fineId] = nil
    end
end)

-- Check if player is in vehicle
function IsInAuthorizedVehicle()
    if not Config.RestrictToVehicle then return true end
    
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then return false end
    
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehicleClass = GetVehicleClass(vehicle)
    
    -- Allow emergency vehicles
    if vehicleClass == 18 then
        return true
    end
    
    return false
end

-- Prevent opening while dead or handcuffed
function CanOpenMDT()
    local playerPed = PlayerPedId()
    
    if IsEntityDead(playerPed) then
        QBCore.Functions.Notify('You cannot open the MDT while dead', 'error')
        return false
    end
    
    if IsPedCuffed(playerPed) then
        QBCore.Functions.Notify('You cannot open the MDT while handcuffed', 'error')
        return false
    end
    
    return true
end

-- Override OpenMDT with checks
local originalOpenMDT = OpenMDT
function OpenMDT()
    if not CanOpenMDT() then return end
    if Config.RestrictToVehicle and not IsInAuthorizedVehicle() then
        QBCore.Functions.Notify('You must be in an emergency vehicle to use the MDT', 'error')
        return
    end
    
    originalOpenMDT()
end

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isOpen then
            CloseMDT()
        end
    end
end)