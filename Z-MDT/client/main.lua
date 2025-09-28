local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isTabletOpen = false
local currentBlips = {}

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

function OpenMDT()
    if isTabletOpen then return end
    
    isTabletOpen = true
    SetNuiFocus(true, true)
    
    -- Get player data for MDT
    QBCore.Functions.TriggerCallback('zmdt:server:getMDTData', function(data)
        SendNUIMessage({
            action = 'openMDT',
            data = data
        })
    end)
    
    -- Tablet animation
    local ped = PlayerPedId()
    RequestAnimDict('amb@world_human_seat_wall_tablet@female@base')
    while not HasAnimDictLoaded('amb@world_human_seat_wall_tablet@female@base') do
        Wait(0)
    end
    
    TaskPlayAnim(ped, 'amb@world_human_seat_wall_tablet@female@base', 'base', 8.0, -8.0, -1, 50, 0, false, false, false)
end

function CloseMDT()
    if not isTabletOpen then return end
    
    isTabletOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'closeMDT'
    })
    
    -- Stop animation
    local ped = PlayerPedId()
    ClearPedTasks(ped)
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

-- Keybind for tablet (optional)
RegisterKeyMapping('openmdt', 'Open MDT Tablet', 'keyboard', 'F6')
RegisterCommand('openmdt', function()
    if HasMDTAccess() then
        TriggerEvent('zmdt:client:useTablet')
    end
end)

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
