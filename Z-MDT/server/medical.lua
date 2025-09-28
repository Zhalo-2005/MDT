-- Z-MDT Medical Records System
   local QBCore = exports['qb-core']:GetCoreObject()
   
   -- Get medical records for a citizen
   QBCore.Functions.CreateCallback('zmdt:server:getMedicalRecords', function(source, cb, citizenid)
       local Player = QBCore.Functions.GetPlayer(source)
       if not Player then return cb({success = false, message = 'Player not found'}) end
       
       -- Check if player has permission to view medical records
       local job = Player.PlayerData.job.name
       local grade = Player.PlayerData.job.grade.level
       local hasPermission = false
       
       if Config.AuthorizedJobs[job] then
           for _, authorizedGrade in pairs(Config.AuthorizedJobs[job].grades) do
               if grade == authorizedGrade and IsJobAllowed(job, 'view_medical') then
                   hasPermission = true
                   break
               end
           end
       end
       
       if not hasPermission then
           return cb({success = false, message = 'You do not have permission to view medical records'})
       end
       
       -- Get medical records
       local records = MySQL.query.await('SELECT * FROM zmdt_medical_records WHERE citizenid = ? ORDER BY created_at DESC', {citizenid})
       
       -- Get medical flags
       local flags = MySQL.query.await('SELECT * FROM zmdt_medical_flags WHERE citizenid = ?', {citizenid})
       
       -- Log action
       LogAction(source, 'VIEW_MEDICAL_RECORDS', 'Viewed medical records for ' .. citizenid)
       
       cb({success = true, data = {records = records or {}, flags = flags or {}}})
   end)
   
   -- Create medical record
   RegisterNetEvent('zmdt:server:createMedicalRecord', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to create medical records
       if not IsJobAllowed(Player.PlayerData.job.name, 'manage_medical_records') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to create medical records', 'error')
           return
       end
       
       -- Generate unique record ID
       local recordId = 'MED-' .. os.time()
       
       -- Insert medical record
       MySQL.insert('INSERT INTO zmdt_medical_records (record_id, citizenid, doctor_id, doctor_name, diagnosis, treatment, notes) VALUES (?, ?, ?, ?, ?, ?, ?)', {
           recordId,
           data.citizenid,
           Player.PlayerData.citizenid,
           Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
           data.diagnosis,
           data.treatment,
           data.notes or ''
       })
       
       -- Log action
       LogAction(src, 'CREATE_MEDICAL_RECORD', 'Created medical record ' .. recordId .. ' for ' .. data.citizenid)
       
       -- Send webhook if configured
       if Config.Webhooks.medical ~= '' then
           local citizenName = GetCitizenName(data.citizenid)
           local message = {
               embeds = {
                   {
                       title = "New Medical Record Created",
                       description = "A new medical record has been created",
                       color = 3447003,
                       fields = {
                           {name = "Record ID", value = recordId, inline = true},
                           {name = "Patient", value = citizenName, inline = true},
                           {name = "Doctor", value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, inline = true},
                           {name = "Diagnosis", value = data.diagnosis, inline = false},
                           {name = "Treatment", value = data.treatment, inline = false}
                       },
                       footer = {
                           text = "Z-MDT System • " .. os.date("%Y-%m-%d %H:%M:%S")
                       }
                   }
               }
           }
           
           PerformHttpRequest(Config.Webhooks.medical, function(err, text, headers) end, 'POST', json.encode(message), {['Content-Type'] = 'application/json'})
       end
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Medical record created successfully', 'success')
       
       -- Update Google Sheets if enabled
       if Config.GoogleSheets.enabled and Config.GoogleSheets.webhook_url ~= '' then
           local sheetData = {
               action = 'add_medical_record',
               record_id = recordId,
               citizenid = data.citizenid,
               citizen_name = GetCitizenName(data.citizenid),
               doctor_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
               diagnosis = data.diagnosis,
               treatment = data.treatment,
               date = os.date("%Y-%m-%d %H:%M:%S")
           }
           
           PerformHttpRequest(Config.GoogleSheets.webhook_url, function(err, text, headers) end, 'POST', json.encode(sheetData), {['Content-Type'] = 'application/json'})
       end
   end)
   
   -- Add medical flag
   RegisterNetEvent('zmdt:server:addMedicalFlag', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to manage medical records
       if not IsJobAllowed(Player.PlayerData.job.name, 'manage_medical_records') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to add medical flags', 'error')
           return
       end
       
       -- Get flag details from config
       local flagFound = false
       local flagLabel = ''
       
       for _, flag in pairs(Config.MedicalFlags) do
           if flag.id == data.flag_id then
               flagFound = true
               flagLabel = flag.label
               break
           end
       end
       
       if not flagFound then
           TriggerClientEvent('QBCore:Notify', src, 'Invalid medical flag', 'error')
           return
       end
       
       -- Insert medical flag
       MySQL.insert('INSERT INTO zmdt_medical_flags (citizenid, flag_id, flag_label, description, added_by, added_by_name) VALUES (?, ?, ?, ?, ?, ?)', {
           data.citizenid,
           data.flag_id,
           flagLabel,
           data.description or '',
           Player.PlayerData.citizenid,
           Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
       })
       
       -- Log action
       LogAction(src, 'ADD_MEDICAL_FLAG', 'Added medical flag ' .. flagLabel .. ' to ' .. data.citizenid)
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Medical flag added successfully', 'success')
   end)
   
   -- Remove medical flag
   RegisterNetEvent('zmdt:server:removeMedicalFlag', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to manage medical records
       if not IsJobAllowed(Player.PlayerData.job.name, 'manage_medical_records') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to remove medical flags', 'error')
           return
       end
       
       -- Delete medical flag
       MySQL.query('DELETE FROM zmdt_medical_flags WHERE id = ? AND citizenid = ?', {data.flag_id, data.citizenid})
       
       -- Log action
       LogAction(src, 'REMOVE_MEDICAL_FLAG', 'Removed medical flag ID ' .. data.flag_id .. ' from ' .. data.citizenid)
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Medical flag removed successfully', 'success')
   end)
   
   -- Create medical incident (for integration with ambulance jobs)
   RegisterNetEvent('zmdt:server:createMedicalIncident', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to create medical incidents
       if not IsJobAllowed(Player.PlayerData.job.name, 'create_medical_incidents') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to create medical incidents', 'error')
           return
       end
       
       -- Generate unique incident ID
       local incidentId = 'MED-' .. os.time()
       
       -- Get patient name
       local patientName = GetCitizenName(data.patientId)
       
       -- Insert incident
       MySQL.insert('INSERT INTO zmdt_incidents (incident_id, title, description, location, coords, officer_id, officer_name, status, priority, type, involved_citizens) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
           incidentId,
           'Medical Incident - ' .. patientName,
           data.treatment or 'Medical treatment provided',
           data.location or 'Hospital',
           data.coords or '{}',
           Player.PlayerData.citizenid,
           Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
           'closed',
           'medium',
           'medical',
           json.encode({data.patientId})
       })
       
       -- Log action
       LogAction(src, 'CREATE_MEDICAL_INCIDENT', 'Created medical incident ' .. incidentId .. ' for ' .. data.patientId)
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Medical incident created successfully', 'success')
   end)
   
   -- Helper function to get citizen name
   function GetCitizenName(citizenid)
       local result = MySQL.query.await('SELECT firstname, lastname FROM zmdt_citizens WHERE citizenid = ?', {citizenid})
       
       if result and #result > 0 then
           return result[1].firstname .. ' ' .. result[1].lastname
       else
           -- Try to get from players table
           local playerResult = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
           if playerResult and #playerResult > 0 then
               local charinfo = json.decode(playerResult[1].charinfo)
               return charinfo.firstname .. ' ' .. charinfo.lastname
           end
       end
       
       return 'Unknown Citizen'
   end
   
   -- Helper function to check if job has permission
   function IsJobAllowed(job, permission)
       if Config.AuthorizedJobs[job] and Config.AuthorizedJobs[job].permissions then
           for _, perm in pairs(Config.AuthorizedJobs[job].permissions) do
               if perm == permission then
                   return true
               end
           end
       end
       
       return false
   end