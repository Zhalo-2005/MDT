-- Z-MDT Medical System

local QBCore = exports['qb-core']:GetCoreObject()
local isMedicalTabletOpen = false
local medicalTabletProp = nil
local medicalTabletDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
local medicalTabletAnim = "base"
local medicalTabletPropName = `prop_cs_tablet`
local medicalTabletBone = 60309

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Check if player is NHS/ambulance and set up any necessary state
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job and PlayerData.job.name == 'ambulance' then
        -- Initialize NHS-specific functionality
    end
end)

-- Medical Tablet Usage
RegisterNetEvent('zmdt:client:useMedicalTablet', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData.job or PlayerData.job.name ~= 'ambulance' then
        QBCore.Functions.Notify('You are not authorized to use the medical tablet', 'error')
        return
    end
    
    OpenMedicalTablet()
end)

-- Create and attach medical tablet prop (different color/style from police tablet)
function AttachMedicalTabletProp()
    if medicalTabletProp then return end
    
    RequestModel(medicalTabletPropName)
    while not HasModelLoaded(medicalTabletPropName) do
        Wait(10)
    end
    
    RequestAnimDict(medicalTabletDict)
    while not HasAnimDictLoaded(medicalTabletDict) do
        Wait(10)
    end
    
    local ped = PlayerPedId()
    local tabletObj = CreateObject(medicalTabletPropName, 0.0, 0.0, 0.0, true, true, false)
    
    AttachEntityToEntity(tabletObj, ped, GetPedBoneIndex(ped, medicalTabletBone), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(medicalTabletPropName)
    
    medicalTabletProp = tabletObj
    
    -- Play animation
    TaskPlayAnim(ped, medicalTabletDict, medicalTabletAnim, 3.0, 3.0, -1, 49, 0, false, false, false)
end

-- Remove medical tablet prop
function RemoveMedicalTabletProp()
    if not medicalTabletProp then return end
    
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    DeleteEntity(medicalTabletProp)
    medicalTabletProp = nil
end

-- Open medical tablet interface
function OpenMedicalTablet()
    if isMedicalTabletOpen then return end
    
    isMedicalTabletOpen = true
    SetNuiFocus(true, true)
    
    -- Attach tablet prop
    AttachMedicalTabletProp()
    
    -- Get player data for MDT
    QBCore.Functions.TriggerCallback('zmdt:server:getMDTData', function(data)
        -- Add medical-specific data
        data.isMedical = true
        data.medicalFlags = Config.MedicalFlags
        
        SendNUIMessage({
            action = 'openMDT',
            data = data
        })
    end)
    
    -- Disable controls while tablet is open
    CreateThread(function()
        while isMedicalTabletOpen do
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
        TriggerServerEvent('fiveroster:server:updateStatus', 'Using Medical Tablet')
    end
end

-- Close medical tablet interface
function CloseMedicalTablet()
    if not isMedicalTabletOpen then return end
    
    isMedicalTabletOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'closeMDT'
    })
    
    -- Remove tablet prop
    RemoveMedicalTabletProp()
    
    -- Reset roster status
    if Config.Integrations.Roster == 'fiveroster' then
        TriggerServerEvent('fiveroster:server:updateStatus', 'Available')
    end
end

-- NUI Callbacks for Medical System
RegisterNUICallback('closeMedicalTablet', function(data, cb)
    CloseMedicalTablet()
    cb('ok')
end)

RegisterNUICallback('getMedicalRecords', function(data, cb)
    QBCore.Functions.TriggerCallback('zmdt:server:getMedicalRecords', function(result)
        cb(result)
    end, data.citizenid)
end)

RegisterNUICallback('createMedicalRecord', function(data, cb)
    TriggerServerEvent('zmdt:server:createMedicalRecord', data)
    cb('ok')
end)

RegisterNUICallback('addMedicalFlag', function(data, cb)
    TriggerServerEvent('zmdt:server:addMedicalFlag', data)
    cb('ok')
end)

RegisterNUICallback('removeMedicalFlag', function(data, cb)
    TriggerServerEvent('zmdt:server:removeMedicalFlag', data)
    cb('ok')
end)

-- Create medical incident from treatment
RegisterNetEvent('zmdt:client:createMedicalIncidentFromTreatment', function(patientId, treatment, location)
    -- Format the data
    local data = {
        patientId = patientId,
        treatment = treatment,
        location = location or 'Hospital'
    }
    
    -- Get current player position if location not provided
    if not location then
        local playerCoords = GetEntityCoords(PlayerPedId())
        data.coords = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }
    end
    
    -- Send to server
    TriggerServerEvent('zmdt:server:createMedicalIncident', data)
end)

-- Item usage
if Config.Integrations.Inventory == 'qb-inventory' then
    -- Use the correct QBCore method for qb-inventory
    QBCore.Functions.CreateUseableItem('zmdt_medical_tablet', function(source, item)
        TriggerClientEvent('zmdt:client:useMedicalTablet', source)
    end)
elseif GetResourceState('ox_inventory') ~= 'missing' then
    -- ox_inventory integration
    exports('useMedicalTablet', function(data, slot)
        TriggerEvent('zmdt:client:useMedicalTablet')
    end)
end

-- Integration with Ambulance Job
if Config.Integrations.Ambulance == 'wasabi_ambulance' then
    -- Hook into Wasabi Ambulance events
    RegisterNetEvent('wasabi_ambulance:patientTreated', function(patientId, treatment)
        -- Auto-create medical incident
        TriggerEvent('zmdt:client:createMedicalIncidentFromTreatment', patientId, treatment)
    end)
end

-- Export functions