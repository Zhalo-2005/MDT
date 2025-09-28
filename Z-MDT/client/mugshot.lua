local inMugshot = false
local mugshotCam = nil
local previousCoords = nil
local previousHeading = nil

-- Take mugshot of a citizen
function TakeMugshot(citizenid)
    if inMugshot then return end
    
    local playerPed = PlayerPedId()
    previousCoords = GetEntityCoords(playerPed)
    previousHeading = GetEntityHeading(playerPed)
    
    local coords = Config.Mugshot.coords
    local camCoords = Config.Mugshot.camera_coords
    
    -- Teleport player to mugshot location
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPed, coords.w)
    
    -- Freeze player
    FreezeEntityPosition(playerPed, true)
    
    -- Create camera
    mugshotCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(mugshotCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(mugshotCam, 0.0, 0.0, camCoords.w)
    SetCamFov(mugshotCam, 50.0)
    RenderScriptCams(true, false, 0, true, true)
    
    inMugshot = true
    
    -- Show instructions
    QBCore.Functions.Notify('Press [E] to take mugshot, [G] to cancel', 'primary', 10000)
    
    -- Input loop
    CreateThread(function()
        while inMugshot do
            Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E key
                -- Take screenshot
                exports['screenshot-basic']:requestScreenshotUpload(Config.Mugshot.upload_url, 'image', function(data)
                    local response = json.decode(data)
                    local imageUrl = ''
                    
                    -- Handle different image upload services
                    if response.url then
                        imageUrl = response.url
                    elseif response.data and response.data.url then
                        imageUrl = response.data.url
                    elseif response.link then
                        imageUrl = response.link
                    elseif response.image then
                        imageUrl = response.image
                    end
                    
                    if imageUrl ~= '' then
                        -- Save mugshot to database
                        TriggerServerEvent('zmdt:server:saveMugshot', citizenid, imageUrl)
                        QBCore.Functions.Notify('Mugshot taken successfully', 'success')
                    else
                        QBCore.Functions.Notify('Failed to upload mugshot', 'error')
                    end
                    
                    EndMugshot()
                end)
                break
            elseif IsControlJustPressed(0, 47) then -- G key
                EndMugshot()
                QBCore.Functions.Notify('Mugshot cancelled', 'error')
                break
            end
            
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Mouse look
            EnableControlAction(0, 2, true) -- Mouse look
            EnableControlAction(0, 38, true) -- E key
            EnableControlAction(0, 47, true) -- G key
        end
    end)
end

-- End mugshot process and return player to previous position
function EndMugshot()
    if not inMugshot then return end
    
    inMugshot = false
    
    -- Destroy camera
    if mugshotCam then
        DestroyCam(mugshotCam, false)
        RenderScriptCams(false, false, 0, true, true)
        mugshotCam = nil
    end
    
    -- Unfreeze player
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    
    -- Teleport back to previous position
    if previousCoords and previousHeading then
        SetEntityCoords(playerPed, previousCoords.x, previousCoords.y, previousCoords.z)
        SetEntityHeading(playerPed, previousHeading)
        previousCoords = nil
        previousHeading = nil
    else
        -- Fallback to police station if previous coords not available
        SetEntityCoords(playerPed, 441.0, -981.0, 30.0)
    end
end

-- Take photo for evidence (not a mugshot)
function TakeEvidencePhoto(incidentId)
    if inMugshot then return end
    
    -- Show instructions
    QBCore.Functions.Notify('Press [E] to take photo, [G] to cancel', 'primary', 10000)
    
    -- Create thread for input handling
    CreateThread(function()
        local inputActive = true
        
        while inputActive do
            Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E key
                -- Take screenshot
                exports['screenshot-basic']:requestScreenshotUpload(Config.Mugshot.upload_url, 'image', function(data)
                    local response = json.decode(data)
                    local imageUrl = ''
                    
                    -- Handle different image upload services
                    if response.url then
                        imageUrl = response.url
                    elseif response.data and response.data.url then
                        imageUrl = response.data.url
                    elseif response.link then
                        imageUrl = response.link
                    elseif response.image then
                        imageUrl = response.image
                    end
                    
                    if imageUrl ~= '' then
                        -- Save evidence photo to database
                        TriggerServerEvent('zmdt:server:saveEvidencePhoto', incidentId, imageUrl)
                        QBCore.Functions.Notify('Photo taken and added to evidence', 'success')
                    else
                        QBCore.Functions.Notify('Failed to upload photo', 'error')
                    end
                    
                    inputActive = false
                end)
                break
            elseif IsControlJustPressed(0, 47) then -- G key
                QBCore.Functions.Notify('Photo cancelled', 'error')
                inputActive = false
                break
            end
        end
    end)
end

-- Register NUI callback for taking evidence photos
RegisterNUICallback('takeEvidencePhoto', function(data, cb)
    TakeEvidencePhoto(data.incidentId)
    cb('ok')
end)

-- Export functions
exports('TakeMugshot', TakeMugshot)
exports('TakeEvidencePhoto', TakeEvidencePhoto)