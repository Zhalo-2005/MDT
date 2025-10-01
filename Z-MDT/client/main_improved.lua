-- Z-MDT Client Main (Fixed Integration)
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

-- Check MDT access based on job type
function HasMDTAccess()
    if not PlayerData.job then return false end
    
    local job = PlayerData.job.name:lower()
    
    local policeJobs = {'police', 'sheriff', 'state', 'fbi', 'dea'}
    local medicalJobs = {'ambulance', 'ems', 'doctor'}
    
    for _, policeJob in ipairs(policeJobs) do
        if job == policeJob then return true end
    end
    
    for _, medicalJob in ipairs(medicalJobs) do
        if job == medicalJob then return true end
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

-- Open MDT
function OpenMDT()
    if isTabletOpen then return end
    
    isTabletOpen = true
    SetNuiFocus(true, true)
    
    AttachTabletProp()
    
    -- Request data from server
    TriggerServerEvent('zmdt:server:getMDTData')
end

-- Close MDT
function CloseMDT()
    if not isTabletOpen then return end
    
    isTabletOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({ action = 'closeMDT' })
    
    RemoveTabletProp()
end

-- NUI Callbacks
RegisterNUICallback('closeMDT', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('searchPerson', function(data, cb)
    TriggerServerEvent('zmdt:server:searchPerson', data)
    cb('ok')
end)

RegisterNUICallback('searchVehicle', function(data, cb)
    TriggerServerEvent('zmdt:server:searchVehicle', data)
    cb('ok')
end)

RegisterNUICallback('createIncident', function(data, cb)
    TriggerServerEvent('zmdt:server:createIncident', data)
    cb('ok')
end)

RegisterNUICallback('createFine', function(data, cb)
    TriggerServerEvent('zmdt:server:createFine', data)
    cb('ok')
end)

RegisterNUICallback('createCustody', function(data, cb)
    TriggerServerEvent('zmdt:server:createCustodyAndJail', data)
    cb('ok')
end)

RegisterNUICallback('releaseCustody', function(data, cb)
    TriggerServerEvent('zmdt:server:releaseFromCustody', data)
    cb('ok')
end)

-- Server event handlers
RegisterNetEvent('zmdt:client:mdtData')
AddEventHandler('zmdt:client:mdtData', function(data)
    if data then
        SendNUIMessage({
            action = 'openMDT',
            data = data
        })
    else
        QBCore.Functions.Notify('Failed to load MDT data', 'error')
        CloseMDT()
    end
end)

RegisterNetEvent('zmdt:client:dashboardStats')
AddEventHandler('zmdt:client:dashboardStats', function(stats)
    SendNUIMessage({
        action = 'dashboardStats',
        stats = stats
    })
end)

RegisterNetEvent('zmdt:client:searchResults')
AddEventHandler('zmdt:client:searchResults', function(results)
    SendNUIMessage({
        action = 'searchResults',
        results = results
    })
end)

RegisterNetEvent('zmdt:client:vehicleSearchResults')
AddEventHandler('zmdt:client:vehicleSearchResults', function(results)
    SendNUIMessage({
        action = 'vehicleSearchResults',
        results = results
    })
end)

RegisterNetEvent('zmdt:client:incidentResults')
AddEventHandler('zmdt:client:incidentResults', function(results)
    SendNUIMessage({
        action = 'incidentResults',
        results = results
    })
end)

RegisterNetEvent('zmdt:client:custodyRecords')
AddEventHandler('zmdt:client:custodyRecords', function(results)
    SendNUIMessage({
        action = 'custodyRecords',
        results = results
    })
end)

RegisterNetEvent('zmdt:client:notification')
AddEventHandler('zmdt:client:notification', function(message, type)
    SendNUIMessage({
        action = 'notification',
        message = message,
        type = type
    })
end)

-- Tablet Usage
RegisterNetEvent('zmdt:client:useTablet', function()
    if not HasMDTAccess() then
        QBCore.Functions.Notify("You don't have access to the MDT system", 'error')
        return
    end
    
    OpenMDT()
end)

-- Keybind for tablet
RegisterKeyMapping('openmdt', 'Open MDT Tablet', 'keyboard', 'F6')
RegisterCommand('openmdt', function()
    if HasMDTAccess() then
        TriggerEvent('zmdt:client:useTablet')
    end
end)

-- Item usage
if Config.Integrations.Inventory == 'qb-inventory' then
    QBCore.Functions.CreateUseableItem(Config.TabletItem, function(source, item)
        TriggerClientEvent('zmdt:client:useTablet', source)
    end)
elseif GetResourceState('ox_inventory') ~= 'missing' then
    exports('useTablet', function(data, slot)
        TriggerEvent('zmdt:client:useTablet')
    end)
end

-- Export functions
exports('HasMDTAccess', HasMDTAccess)
exports('OpenMDT', OpenMDT)
exports('CloseMDT', CloseMDT)