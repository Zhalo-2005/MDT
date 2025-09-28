local inMugshot = false
local mugshotCam = nil

function TakeMugshot(citizenid)
    if inMugshot then return end
    
    local playerPed = PlayerPedId()
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
                exports['screenshot-basic']:requestScreenshotUpload('https://your-image-upload-service.com/upload', 'image', function(data)
                    local imageUrl = json.decode(data).url
                    
                    -- Save mugshot to database
                    TriggerServerEvent('zmdt:server:saveMugshot', citizenid, imageUrl)
                    
                    EndMugshot()
                    QBCore.Functions.Notify('Mugshot taken successfully', 'success')
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
        end
    end)
end

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
    
    -- Teleport back (you might want to save previous coords)
    SetEntityCoords(playerPed, 441.0, -981.0, 30.0) -- Police station
end

-- Server event for saving mugshot
RegisterNetEvent('zmdt:server:saveMugshot', function(citizenid, imageUrl)
    MySQL.query('UPDATE zmdt_citizens SET mugshot = ? WHERE citizenid = ?', {imageUrl, citizenid})
    
    -- Log action
    LogAction(source, 'TAKE_MUGSHOT', 'Took mugshot for ' .. citizenid)
end)
