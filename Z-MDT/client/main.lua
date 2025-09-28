local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isTabletOpen = false
local currentBlips = {}
local tabletProp = nil
local tabletDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
local tabletAnim = "base"
local tabletPropName = `prop_cs_tablet`
local tabletBone = 60309

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Tablet Usage
RegisterNetEvent('zmdt:client:useTablet', function()
    if not HasMDTAccess() then
        QBCore.Functions.Notify('You don\'t have access to the MDT system', 'error')
        return
    end
    
    OpenMDT()
end)

-- Check if player has MDT access based on job and grade
function HasMDTAccess()
    if not PlayerData.job then return false end
    
    local job = PlayerData.job.name
    local grade = PlayerData.job.grade.level
    
    if Config.AuthorizedJobs[job] then
        for _, authorizedGrade in pairs(Config.AuthorizedJobs[job].grades) do
            if grade == authorizedGrade then
                return true
            end
        end
    end
    
    return false
end

-- Create and attach tablet prop
function AttachTabletProp()
    if tabletProp then return end
    
    RequestModel(tabletPropName)
    while not HasModelLoaded(tabletPropName) do
        Wait(10)
    end
    
    RequestAnimDict(tabletDict)
    while not HasAnimDictLoaded(tabletDict) do
        Wait(10)
    end
    
    local ped = PlayerPedId()
    local tabletObj = CreateObject(tabletPropName, 0.0, 0.0, 0.0, true, true, false)
    
    AttachEntityToEntity(tabletObj, ped, GetPedBoneIndex(ped, tabletBone), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(tabletPropName)
    
    tabletProp = tabletObj
    
    -- Play animation
    TaskPlayAnim(ped, tabletDict, tabletAnim, 3.0, 3.0, -1, 49, 0, false, false, false)
end

-- Remove tablet prop
function RemoveTabletProp()
    if not tabletProp then return end
    
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    DeleteEntity(tabletProp)
    tabletProp = nil
end

-- Open MDT interface
function OpenMDT()
    if isTabletOpen then return end
    
    isTabletOpen = true
    SetNuiFocus(true, true)
    
    -- Attach tablet prop
    AttachTabletProp()
    
    -- Get player data for MDT
    QBCore.Functions.TriggerCallback('zmdt:server:getMDTData', function(data)
        SendNUIMessage({
            action = 'openMDT',
            data = data
        })
    end)
    
    -- Disable controls while tablet is open
    CreateThread(function()
        while isTabletOpen do
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 257, true) -- Attack2
            DisableControlAction(0, 263, true) -- Melee Attack1
            DisablePlayerFiring(PlayerId(), true) -- Disable weapon firing
            Wait(0)
        end
    end)
    
    -- Tablet usage notification
    if Config.Integrations.Roster == 'fiveroster' then
        TriggerServerEvent('fiveroster:server:updateStatus', 'Using MDT')
    end
end

-- Close MDT interface
function CloseMDT()
    if not isTabletOpen then return end
    
    isTabletOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'closeMDT'
    })
    
    -- Remove tablet prop
    RemoveTabletProp()
    
    -- Reset roster status
    if Config.Integrations.Roster == 'fiveroster' then
        TriggerServerEvent('fiveroster:server:updateStatus', 'Available')
    end
end

-- NUI Callbacks
RegisterNUICallback('closeMDT', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('searchPerson', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:searchPerson', function(result)
        cb(result)
    end, data.query)
end)

RegisterNUICallback('searchVehicle', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:searchVehicle', function(result)
        cb(result)
    end, data.query)
end)

RegisterNUICallback('createIncident', function(data, cb)
    TriggerServerEvent('zmdt:server:createIncident', data)
    cb('ok')
end)

RegisterNUICallback('issueFine', function(data, cb)
    TriggerServerEvent('zmdt:server:issueFine', data)
    cb('ok')
end)

RegisterNUICallback('createWarrant', function(data, cb)
    TriggerServerEvent('zmdt:server:createWarrant', data)
    cb('ok')
end)

RegisterNUICallback('takeMugshot', function(data, cb)
    TakeMugshot(data.citizenid)
    cb('ok')
end)

RegisterNUICallback('updatePerson', function(data, cb)
    TriggerServerEvent('zmdt:server:updatePerson', data)
    cb('ok')
end)

RegisterNUICallback('updateVehicle', function(data, cb)
    TriggerServerEvent('zmdt:server:updateVehicle', data)
    cb('ok')
end)

RegisterNUICallback('createCustody', function(data, cb)
    TriggerServerEvent('zmdt:server:createCustody', data)
    cb('ok')
end)

RegisterNUICallback('releaseCustody', function(data, cb)
    TriggerServerEvent('zmdt:server:releaseCustody', data)
    cb('ok')
end)

RegisterNUICallback('createMedicalRecord', function(data, cb)
    TriggerServerEvent('zmdt:server:createMedicalRecord', data)
    cb('ok')
end)

-- Blip Management
RegisterNetEvent('zmdt:client:createFineBlip', function(coords, fineId)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Blips.fine_payment.sprite)
    SetBlipColour(blip, Config.Blips.fine_payment.color)
    SetBlipScale(blip, Config.Blips.fine_payment.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blips.fine_payment.label)
    EndTextCommandSetBlipName(blip)
    
    currentBlips[fineId] = blip
end)

RegisterNetEvent('zmdt:client:removeFineBlip', function(fineId)
    if currentBlips[fineId] then
        RemoveBlip(currentBlips[fineId])
        currentBlips[fineId] = nil
    end
end)

RegisterNetEvent('zmdt:client:createIncidentBlip', function(coords, incidentId)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Blips.incident.sprite)
    SetBlipColour(blip, Config.Blips.incident.color)
    SetBlipScale(blip, Config.Blips.incident.scale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blips.incident.label)
    EndTextCommandSetBlipName(blip)
    
    currentBlips['incident_' .. incidentId] = blip
end)

RegisterNetEvent('zmdt:client:removeIncidentBlip', function(incidentId)
    if currentBlips['incident_' .. incidentId] then
        RemoveBlip(currentBlips['incident_' .. incidentId])
        currentBlips['incident_' .. incidentId] = nil
    end
end)

-- Keybind for tablet (optional)
RegisterKeyMapping('openmdt', 'Open MDT Tablet', 'keyboard', 'F6')
RegisterCommand('openmdt', function()
    if HasMDTAccess() then
        TriggerEvent('zmdt:client:useTablet')
    end
end)

-- Item usage
if Config.Integrations.Inventory == 'qb-inventory' then
    QBCore.Functions.CreateUseableItem(Config.TabletItem, function(source)
        TriggerEvent('zmdt:client:useTablet')
    end)
elseif GetResourceState('ox_inventory') ~= 'missing' then
    -- ox_inventory integration is handled via exports in items.lua
    exports('useTablet', function(data, slot)
        TriggerEvent('zmdt:client:useTablet')
    end)
end

-- Integration with Wasabi Police
if Config.Integrations.Police == 'wasabi_police' then
    -- Hook into Wasabi Police events
    RegisterNetEvent('wasabi_police:arrestPlayer', function(targetId, charges)
        -- Auto-create custody record
        TriggerServerEvent('zmdt:server:createCustody', {
            targetId = targetId,
            charges = charges
        })
    end)
end

-- Integration with Wasabi Ambulance
if Config.Integrations.Ambulance == 'wasabi_ambulance' then
    -- Hook into Wasabi Ambulance events
    RegisterNetEvent('wasabi_ambulance:patientTreated', function(patientId, treatment)
        -- Auto-create medical incident
        TriggerServerEvent('zmdt:server:createMedicalIncident', {
            patientId = patientId,
            treatment = treatment
        })
    end)
end