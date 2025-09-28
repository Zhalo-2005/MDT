-- Z-MDT Fines System
   local QBCore = exports['qb-core']:GetCoreObject()
   
   -- Get fines for a citizen
   QBCore.Functions.CreateCallback('zmdt:server:getCitizenFines', function(source, cb, citizenid)
       local Player = QBCore.Functions.GetPlayer(source)
       if not Player then return cb({success = false, message = 'Player not found'}) end
       
       -- Get fines
       local fines = MySQL.query.await('SELECT * FROM zmdt_fines WHERE citizenid = ? ORDER BY created_at DESC', {citizenid})
       
       -- Parse charges from JSON
       for i, fine in ipairs(fines) do
           if fine.charges then
               fines[i].charges_parsed = json.decode(fine.charges) or {}
           else
               fines[i].charges_parsed = {}
           end
       end
       
       cb({success = true, data = fines or {}})
   end)
   
   -- Get all fines with filter
   QBCore.Functions.CreateCallback('zmdt:server:getAllFines', function(source, cb, filter)
       local Player = QBCore.Functions.GetPlayer(source)
       if not Player then return cb({success = false, message = 'Player not found'}) end
       
       -- Check if player has permission to view fines
       local job = Player.PlayerData.job.name
       local grade = Player.PlayerData.job.grade.level
       local hasPermission = false
       
       if Config.AuthorizedJobs[job] then
           for _, authorizedGrade in pairs(Config.AuthorizedJobs[job].grades) do
               if grade == authorizedGrade and IsJobAllowed(job, 'issue_fines') then
                   hasPermission = true
                   break
               end
           end
       end
       
       if not hasPermission then
           return cb({success = false, message = 'You do not have permission to view fines'})
       end
       
       -- Build query based on filter
       local query = 'SELECT f.*, c.firstname, c.lastname FROM zmdt_fines f LEFT JOIN zmdt_citizens c ON f.citizenid = c.citizenid'
       local params = {}
       
       if filter then
           if filter.status then
               query = query .. ' WHERE f.status = ?'
               params[#params + 1] = filter.status
           end
           
           if filter.citizenid then
               if #params > 0 then
                   query = query .. ' AND f.citizenid = ?'
               else
                   query = query .. ' WHERE f.citizenid = ?'
               end
               params[#params + 1] = filter.citizenid
           end
       end
       
       query = query .. ' ORDER BY f.created_at DESC LIMIT 100'
       
       -- Get fines
       local fines = MySQL.query.await(query, params)
       
       -- Process fines to add citizen names if not available from join
       for i, fine in ipairs(fines) do
           if not fine.firstname or not fine.lastname then
               local citizenName = GetCitizenName(fine.citizenid)
               local nameParts = SplitString(citizenName, ' ')
               fines[i].firstname = nameParts[1] or 'Unknown'
               fines[i].lastname = nameParts[2] or ''
           end
           
           -- Parse charges from JSON
           if fine.charges then
               fines[i].charges_parsed = json.decode(fine.charges) or {}
           else
               fines[i].charges_parsed = {}
           end
       end
       
       -- Log action
       LogAction(source, 'VIEW_FINES', 'Viewed fines list')
       
       cb({success = true, data = fines or {}})
   end)
   
   -- Issue fine
   RegisterNetEvent('zmdt:server:issueFine', function(data)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to issue fines
       if not IsJobAllowed(Player.PlayerData.job.name, 'issue_fines') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to issue fines', 'error')
           return
       end
       
       -- Generate unique fine ID
       local fineId = 'FINE-' .. os.time()
       
       -- Process charges
       local charges = data.charges
       if type(charges) ~= 'string' then
           charges = json.encode(charges)
       end
       
       -- Calculate total amount and penalty points
       local totalAmount = data.total_amount or 0
       local penaltyPoints = data.penalty_points or 0
       
       -- If charges are provided as an array of charge objects
       if data.charges_array then
           totalAmount = 0
           penaltyPoints = 0
           
           for _, charge in pairs(data.charges_array) do
               totalAmount = totalAmount + (charge.fine or 0)
               penaltyPoints = penaltyPoints + (charge.points or 0)
           end
       end
       
       -- Set due date (default 14 days)
       local dueDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (14 * 24 * 60 * 60))
       
       -- Set payment location
       local paymentLocation = nil
       if data.payment_location then
           paymentLocation = json.encode(data.payment_location)
       else
           -- Select random payment location from config
           local randomLocation = Config.FinePaymentLocations[math.random(#Config.FinePaymentLocations)]
           paymentLocation = json.encode(randomLocation.coords)
       end
       
       -- Insert fine
       MySQL.insert('INSERT INTO zmdt_fines (fine_id, citizenid, charges, total_amount, penalty_points, issued_by, issued_by_name, status, payment_coords, due_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
           fineId,
           data.citizenid,
           charges,
           totalAmount,
           penaltyPoints,
           Player.PlayerData.citizenid,
           Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
           'unpaid',
           paymentLocation,
           dueDate
       })
       
       -- Update citizen penalty points
       if penaltyPoints > 0 then
           MySQL.query('UPDATE zmdt_citizens SET penalty_points = penalty_points + ? WHERE citizenid = ?', {penaltyPoints, data.citizenid})
       end
       
       -- Log action
       LogAction(src, 'ISSUE_FINE', 'Issued fine ' .. fineId .. ' to ' .. data.citizenid .. ' for £' .. totalAmount)
       
       -- Send webhook if configured
       if Config.Webhooks.fines ~= '' then
           local citizenName = GetCitizenName(data.citizenid)
           local message = {
               embeds = {
                   {
                       title = "New Fine Issued",
                       description = "A new fine has been issued",
                       color = 15105570,
                       fields = {
                           {name = "Fine ID", value = fineId, inline = true},
                           {name = "Citizen", value = citizenName, inline = true},
                           {name = "Officer", value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, inline = true},
                           {name = "Amount", value = "£" .. totalAmount, inline = true},
                           {name = "Penalty Points", value = penaltyPoints, inline = true},
                           {name = "Due Date", value = dueDate, inline = true}
                       },
                       footer = {
                           text = "Z-MDT System • " .. os.date("%Y-%m-%d %H:%M:%S")
                       }
                   }
               }
           }
           
           PerformHttpRequest(Config.Webhooks.fines, function(err, text, headers) end, 'POST', json.encode(message), {['Content-Type'] = 'application/json'})
       end
       
       -- Create blip for payment location
       local paymentCoords = json.decode(paymentLocation)
       TriggerClientEvent('zmdt:client:createFineBlip', src, paymentCoords, fineId)
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Fine issued successfully', 'success')
       
       -- Find target player if online
       local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.citizenid)
       if targetPlayer then
           TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have received a fine of £' .. totalAmount, 'error')
           TriggerClientEvent('zmdt:client:createFineBlip', targetPlayer.PlayerData.source, paymentCoords, fineId)
       end
       
       -- Update Google Sheets if enabled
       if Config.GoogleSheets.enabled and Config.GoogleSheets.webhook_url ~= '' then
           local sheetData = {
               action = 'add_fine',
               fine_id = fineId,
               citizenid = data.citizenid,
               citizen_name = GetCitizenName(data.citizenid),
               officer_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
               amount = totalAmount,
               penalty_points = penaltyPoints,
               due_date = dueDate,
               date_issued = os.date("%Y-%m-%d %H:%M:%S")
           }
           
           PerformHttpRequest(Config.GoogleSheets.webhook_url, function(err, text, headers) end, 'POST', json.encode(sheetData), {['Content-Type'] = 'application/json'})
       end
   end)
   
   -- Pay fine
   RegisterNetEvent('zmdt:server:payFine', function(fineId)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Get fine details
       local fine = MySQL.query.await('SELECT * FROM zmdt_fines WHERE fine_id = ?', {fineId})
       
       if not fine or #fine == 0 then
           TriggerClientEvent('QBCore:Notify', src, 'Fine not found', 'error')
           return
       end
       
       fine = fine[1]
       
       -- Check if fine is already paid
       if fine.status == 'paid' then
           TriggerClientEvent('QBCore:Notify', src, 'This fine has already been paid', 'error')
           return
       end
       
       -- Check if player has enough money
       local accountType = Config.Banking.account_type
       local playerMoney = 0
       
       if accountType == 'cash' then
           playerMoney = Player.PlayerData.money.cash
       else
           playerMoney = Player.PlayerData.money.bank
       end
       
       if playerMoney < fine.total_amount then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to pay this fine', 'error')
           return
       end
       
       -- Process payment based on banking integration
       local paymentSuccess = false
       
       if Config.Integrations.Banking == 'okokBanking' then
           -- okokBanking integration
           exports['okokBanking']:RemoveMoney(src, fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           exports['okokBanking']:AddMoney(Config.Banking.fine_account, fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           paymentSuccess = true
       elseif Config.Integrations.Banking == 'qb-banking' then
           -- qb-banking integration
           if accountType == 'cash' then
               Player.Functions.RemoveMoney('cash', fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           else
               Player.Functions.RemoveMoney('bank', fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           end
           exports['qb-management']:AddMoney(Config.Banking.fine_account, fine.total_amount)
           paymentSuccess = true
       elseif Config.Integrations.Banking == 'codm-banking' then
           -- codm-banking integration
           exports['codm-banking']:RemoveMoney(src, accountType, fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           exports['codm-banking']:AddMoneyToSociety(Config.Banking.fine_account, fine.total_amount)
           paymentSuccess = true
       elseif Config.Integrations.Banking == 'qb-management' then
           -- Direct qb-management integration
           if accountType == 'cash' then
               Player.Functions.RemoveMoney('cash', fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           else
               Player.Functions.RemoveMoney('bank', fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           end
           exports['qb-management']:AddMoney(Config.Banking.fine_account, fine.total_amount)
           paymentSuccess = true
       else
           -- Default QBCore money handling
           if accountType == 'cash' then
               Player.Functions.RemoveMoney('cash', fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           else
               Player.Functions.RemoveMoney('bank', fine.total_amount, 'Fine Payment: ' .. fine.fine_id)
           end
           paymentSuccess = true
       end
       
       if paymentSuccess then
           -- Update fine status
           MySQL.update('UPDATE zmdt_fines SET status = ?, paid_at = NOW() WHERE fine_id = ?', {'paid', fineId})
           
           -- Log action
           LogAction(src, 'PAY_FINE', 'Paid fine ' .. fineId .. ' for £' .. fine.total_amount)
           
           -- Send webhook if configured
           if Config.Webhooks.fines ~= '' then
               local citizenName = GetCitizenName(fine.citizenid)
               local message = {
                   embeds = {
                       {
                           title = "Fine Payment",
                           description = "A fine has been paid",
                           color = 3066993,
                           fields = {
                               {name = "Fine ID", value = fineId, inline = true},
                               {name = "Citizen", value = citizenName, inline = true},
                               {name = "Amount", value = "£" .. fine.total_amount, inline = true},
                               {name = "Payment Date", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true}
                           },
                           footer = {
                               text = "Z-MDT System • " .. os.date("%Y-%m-%d %H:%M:%S")
                           }
                       }
                   }
               }
               
               PerformHttpRequest(Config.Webhooks.fines, function(err, text, headers) end, 'POST', json.encode(message), {['Content-Type'] = 'application/json'})
           end
           
           -- Remove blip
           TriggerClientEvent('zmdt:client:removeFineBlip', src, fineId)
           
           -- Notify client
           TriggerClientEvent('QBCore:Notify', src, 'Fine paid successfully', 'success')
           
           -- Update Google Sheets if enabled
           if Config.GoogleSheets.enabled and Config.GoogleSheets.webhook_url ~= '' then
               local sheetData = {
                   action = 'update_fine',
                   fine_id = fineId,
                   status = 'paid',
                   paid_at = os.date("%Y-%m-%d %H:%M:%S")
               }
               
               PerformHttpRequest(Config.GoogleSheets.webhook_url, function(err, text, headers) end, 'POST', json.encode(sheetData), {['Content-Type'] = 'application/json'})
           end
       else
           TriggerClientEvent('QBCore:Notify', src, 'Failed to process payment', 'error')
       end
   end)
   
   -- Cancel fine
   RegisterNetEvent('zmdt:server:cancelFine', function(fineId)
       local src = source
       local Player = QBCore.Functions.GetPlayer(src)
       if not Player then return end
       
       -- Check if player has permission to issue fines (required to cancel)
       if not IsJobAllowed(Player.PlayerData.job.name, 'issue_fines') then
           TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to cancel fines', 'error')
           return
       end
       
       -- Get fine details
       local fine = MySQL.query.await('SELECT * FROM zmdt_fines WHERE fine_id = ?', {fineId})
       
       if not fine or #fine == 0 then
           TriggerClientEvent('QBCore:Notify', src, 'Fine not found', 'error')
           return
       end
       
       fine = fine[1]
       
       -- Check if fine is already paid
       if fine.status == 'paid' then
           TriggerClientEvent('QBCore:Notify', src, 'Cannot cancel a paid fine', 'error')
           return
       end
       
       -- Update fine status
       MySQL.update('UPDATE zmdt_fines SET status = ? WHERE fine_id = ?', {'cancelled', fineId})
       
       -- Revert penalty points
       if fine.penalty_points > 0 then
           MySQL.query('UPDATE zmdt_citizens SET penalty_points = GREATEST(0, penalty_points - ?) WHERE citizenid = ?', {fine.penalty_points, fine.citizenid})
       end
       
       -- Log action
       LogAction(src, 'CANCEL_FINE', 'Cancelled fine ' .. fineId)
       
       -- Send webhook if configured
       if Config.Webhooks.fines ~= '' then
           local citizenName = GetCitizenName(fine.citizenid)
           local message = {
               embeds = {
                   {
                       title = "Fine Cancelled",
                       description = "A fine has been cancelled",
                       color = 10038562,
                       fields = {
                           {name = "Fine ID", value = fineId, inline = true},
                           {name = "Citizen", value = citizenName, inline = true},
                           {name = "Amount", value = "£" .. fine.total_amount, inline = true},
                           {name = "Cancelled By", value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, inline = true}
                       },
                       footer = {
                           text = "Z-MDT System • " .. os.date("%Y-%m-%d %H:%M:%S")
                       }
                   }
               }
           }
           
           PerformHttpRequest(Config.Webhooks.fines, function(err, text, headers) end, 'POST', json.encode(message), {['Content-Type'] = 'application/json'})
       end
       
       -- Remove blip for all players
       TriggerClientEvent('zmdt:client:removeFineBlip', -1, fineId)
       
       -- Notify client
       TriggerClientEvent('QBCore:Notify', src, 'Fine cancelled successfully', 'success')
       
       -- Find target player if online
       local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(fine.citizenid)
       if targetPlayer then
           TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Your fine has been cancelled', 'success')
           TriggerClientEvent('zmdt:client:removeFineBlip', targetPlayer.PlayerData.source, fineId)
       end
       
       -- Update Google Sheets if enabled
       if Config.GoogleSheets.enabled and Config.GoogleSheets.webhook_url ~= '' then
           local sheetData = {
               action = 'update_fine',
               fine_id = fineId,
               status = 'cancelled',
               cancelled_by = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
               cancelled_at = os.date("%Y-%m-%d %H:%M:%S")
           }
           
           PerformHttpRequest(Config.GoogleSheets.webhook_url, function(err, text, headers) end, 'POST', json.encode(sheetData), {['Content-Type'] = 'application/json'})
       end
   end)
   
   -- Helper function to split string
   function SplitString(inputstr, sep)
       if sep == nil then sep = "%s" end
       local t = {}
       for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
           table.insert(t, str)
       end
       return t
   end