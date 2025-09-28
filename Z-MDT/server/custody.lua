-- Z-MDT Custody System
   local QBCore = exports['qb-core']:GetCoreObject()
   
   -- Get custody records
   QBCore.Functions.CreateCallback('zmdt:server:getCustodyRecords', function(source, cb, filter)
       local Player = QBCore.Functions.GetPlayer(source)
       if not Player then return cb({success = false, message = 'Player not found'}) end
       
       -- Check if player has permission to view custody records
       local job = Player.PlayerData.job.name
       local grade = Player.PlayerData.job.grade.level
       local hasPermission = false
       
       if Config.AuthorizedJobs[job] then
           for _, authorizedGrade in pairs(Config.AuthorizedJobs[job].grades) do
               if grade == authorizedGrade and IsJobAllowed(job, 'view_custody') then
                   hasPermission = true
                   break
               end
           end
       end
       
       if not hasPermission then
           return cb({success = false, message = 'You do not have permission to view custody records'})
       end
       
       -- Build query based on filter
       local query = 'SELECT c.*, cit.firstname, cit.lastname FROM zmdt_custody c LEFT JOIN zmdt_citizens cit ON c.citizenid = cit.citizenid'
       local params = {}
       
       if filter then
           if filter.status then
               query = query .. ' WHERE c.status = ?'
               params[#params + 1] = filter.status
           end
           
           if filter.citizenid then
               if #params > 0 then
                   query = query .. ' AND c.citizenid = ?'
               else
                   query = query .. ' WHERE c.citizenid = ?'
               end
               params[#params + 1] = filter.citizenid
           end
       end
       
       query = query .. ' ORDER BY c.arrested_at DESC'
       
       -- Get custody records
       local records = MySQL.query.await(query, params)
       
       -- Process records to add citizen names if not available from join
       for i, record in ipairs(records) do
           if not record.firstname or not record.lastname then
               local citizenName = GetCitizenName(record.citizenid)
               local nameParts = SplitString(citizenName, ' ')
               records[i].firstname = nameParts[1] or 'Unknown'
               records[i].lastname = nameParts[2] or ''
           end
           
           -- Parse charges from JSON
           if record.charges then
               records[i].charges_parsed = json.decode(record.charges) or {}
           else
               records[i].charges_parsed = {}
           end
       end
       
       -- Log action
       LogAction(source, 'VIEW_CUSTODY_RECORDS', 'Viewed custody records')
       
       cb({success = true, data = records or {}})
   end)
   
   -- Create custody record
   RegisterNetEvent('zmdt:server:createCustody', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to manage custody
       if not IsJobAllowed(Player.PlayerData.job.name, 'manage_custody') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to create custody records', 'error')
           return
       end
       
       -- Get target player
       local targetId = data.targetId
       local targetPlayer = QBCore.Functions.GetPlayer(targetId)
       local citizenid = nil
       
       if targetPlayer then
           -- Target is online
           citizenid = targetPlayer.PlayerData.citizenid
       else
           -- Target might be offline, check if citizenid was provided directly
           citizenid = data.citizenid
       end
       
       if not citizenid then
           TriggerClientEvent('QBCore:Notify', src, 'Invalid citizen ID', 'error')
           return
       end
       
       -- Process charges
       local charges = data.charges
       if type(charges) ~= 'string' then
           charges = json.encode(charges)
       end
       
       -- Calculate custody time and bail amount
       local custodyTime = data.custody_time or 0
       local bailAmount = data.bail_amount or 0
       
       -- If charges are provided as an array of charge objects
       if data.charges_array then
           custodyTime = 0
           bailAmount = 0
           
           for _, charge in pairs(data.charges_array) do
               custodyTime = custodyTime + (charge.time or 0)
               bailAmount = bailAmount + (charge.bail or 0)
           end
       end
       
       -- Assign cell if provided
       local cellNumber = data.cell_number
       
       -- Insert custody record
       MySQL.insert('INSERT INTO zmdt_custody (citizenid, charges, arresting_officer, officer_name, custody_time, bail_amount, status, cell_number, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
           citizenid,
           charges,
           Player.PlayerData.citizenid,
           Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
           custodyTime,
           bailAmount,
           'in_custody',
           cellNumber,
           data.notes or ''
       })
       
       -- Log action
       LogAction(src, 'CREATE_CUSTODY_RECORD', 'Created custody record for ' .. citizenid)
       
       -- Send webhook if configured
       if Config.Webhooks.custody ~= '' then
           local citizenName = GetCitizenName(citizenid)
           local message = {
               embeds = {
                   {
                       title = "New Custody Record",
                       description = "A citizen has been taken into custody",
                       color = 15158332,
                       fields = {
                           {name = "Citizen", value = citizenName, inline = true},
                           {name = "Officer", value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, inline = true},
                           {name = "Custody Time", value = custodyTime .. " months", inline = true},
                           {name = "Bail Amount", value = "£" .. bailAmount, inline = true},
                           {name = "Cell Number", value = cellNumber or "Not assigned", inline = true},
                           {name = "Status", value = "In Custody", inline = true}
                       },
                       footer = {
                           text = "Z-MDT System • " .. os.date("%Y-%m-%d %H:%M:%S")
                       }
                   }
               }
           }
           
           PerformHttpRequest(Config.Webhooks.custody, function(err, text, headers) end, 'POST', json.encode(message), {['Content-Type'] = 'application/json'})
       end
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Custody record created successfully', 'success')
       
       -- If target is online, notify them
       if targetPlayer then
           TriggerClientEvent('QBCore:Notify', targetId, 'You have been taken into custody', 'error')
           
           -- Additional integration with jail systems could be added here
           -- For example, trigger jail events for ESX/QB jail resources
       end
   end)
   
   -- Release from custody
   RegisterNetEvent('zmdt:server:releaseCustody', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to manage custody
       if not IsJobAllowed(Player.PlayerData.job.name, 'manage_custody') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to release from custody', 'error')
           return
       end
       
       -- Get custody record
       local record = MySQL.query.await('SELECT * FROM zmdt_custody WHERE id = ?', {data.id})
       
       if not record or #record == 0 then
           TriggerClientEvent('QBCore:Notify', src, 'Custody record not found', 'error')
           return
       end
       
       -- Update custody record
       MySQL.update('UPDATE zmdt_custody SET status = ?, released_at = NOW() WHERE id = ?', {
           data.status or 'released',
           data.id
       })
       
       -- Log action
       LogAction(src, 'RELEASE_CUSTODY', 'Released ' .. record[1].citizenid .. ' from custody')
       
       -- Send webhook if configured
       if Config.Webhooks.custody ~= '' then
           local citizenName = GetCitizenName(record[1].citizenid)
           local message = {
               embeds = {
                   {
                       title = "Custody Release",
                       description = "A citizen has been released from custody",
                       color = 3066993,
                       fields = {
                           {name = "Citizen", value = citizenName, inline = true},
                           {name = "Officer", value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, inline = true},
                           {name = "Status", value = data.status == 'bailed' and 'Released on Bail' or 'Released', inline = true},
                           {name = "Time Served", value = FormatTimeServed(record[1].arrested_at), inline = true}
                       },
                       footer = {
                           text = "Z-MDT System • " .. os.date("%Y-%m-%d %H:%M:%S")
                       }
                   }
               }
           }
           
           PerformHttpRequest(Config.Webhooks.custody, function(err, text, headers) end, 'POST', json.encode(message), {['Content-Type'] = 'application/json'})
       end
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Citizen released from custody', 'success')
       
       -- Find target player if online
       local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(record[1].citizenid)
       if targetPlayer then
           TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been released from custody', 'success')
           
           -- Additional integration with jail systems could be added here
           -- For example, trigger unjail events for ESX/QB jail resources
       end
   end)
   
   -- Update custody record
   RegisterNetEvent('zmdt:server:updateCustody', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to manage custody
       if not IsJobAllowed(Player.PlayerData.job.name, 'manage_custody') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to update custody records', 'error')
           return
       end
       
       -- Build update query
       local query = 'UPDATE zmdt_custody SET '
       local params = {}
       local updates = {}
       
       if data.cell_number ~= nil then
           table.insert(updates, 'cell_number = ?')
           table.insert(params, data.cell_number)
       end
       
       if data.notes ~= nil then
           table.insert(updates, 'notes = ?')
           table.insert(params, data.notes)
       end
       
       if data.bail_amount ~= nil then
           table.insert(updates, 'bail_amount = ?')
           table.insert(params, data.bail_amount)
       end
       
       if data.custody_time ~= nil then
           table.insert(updates, 'custody_time = ?')
           table.insert(params, data.custody_time)
       end
       
       if #updates == 0 then
           TriggerClientEvent('QBCore:Notify', src, 'No updates provided', 'error')
           return
       end
       
       query = query .. table.concat(updates, ', ') .. ' WHERE id = ?'
       table.insert(params, data.id)
       
       -- Update custody record
       MySQL.update(query, params)
       
       -- Log action
       LogAction(src, 'UPDATE_CUSTODY', 'Updated custody record ' .. data.id)
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Custody record updated successfully', 'success')
   end)
   
   -- Helper function to format time served
   function FormatTimeServed(arrestedAt)
       local arrestTime = os.time(ParseDate(arrestedAt))
       local currentTime = os.time()
       local diffSeconds = currentTime - arrestTime
       
       local days = math.floor(diffSeconds / 86400)
       local hours = math.floor((diffSeconds % 86400) / 3600)
       local minutes = math.floor((diffSeconds % 3600) / 60)
       
       local result = ""
       if days > 0 then result = result .. days .. "d " end
       if hours > 0 then result = result .. hours .. "h " end
       result = result .. minutes .. "m"
       
       return result
   end
   
   -- Helper function to parse date string
   function ParseDate(dateString)
       local year, month, day, hour, min, sec = dateString:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
       return {
           year = tonumber(year),
           month = tonumber(month),
           day = tonumber(day),
           hour = tonumber(hour),
           min = tonumber(min),
           sec = tonumber(sec)
       }
   end
   
   -- Helper function to split string
   function SplitString(inputstr, sep)
       if sep == nil then sep = "%s" end
       local t = {}
       for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
           table.insert(t, str)
       end
       return t
   end