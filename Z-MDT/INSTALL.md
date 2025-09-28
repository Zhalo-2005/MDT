# Z-MDT Installation Guide

This guide will help you install and configure the Z-MDT system on your FiveM server.

## Prerequisites

Before installing Z-MDT, ensure you have the following:

- A running FiveM server with QB-Core or QBox framework
- oxmysql installed and configured
- screenshot-basic resource installed (for mugshots and evidence photos)
- ox_lib (recommended for enhanced UI elements)
- Database access to import SQL files

## Step 1: Download and Extract

1. Download the latest release from GitHub
2. Extract the Z-MDT folder to your server's resources directory
3. Ensure the folder structure is correct: `/resources/Z-MDT/`

## Step 2: Database Setup

1. Access your database management tool (phpMyAdmin, HeidiSQL, etc.)
2. Select your FiveM server database
3. Import the SQL file located at `Z-MDT/sql/install.sql`
4. Verify that the following tables were created:
   - zmdt_citizens
   - zmdt_vehicles
   - zmdt_incidents
   - zmdt_warrants
   - zmdt_fines
   - zmdt_custody
   - zmdt_audit_logs
   - zmdt_dispatch_calls
   - zmdt_medical_records
   - zmdt_medical_flags
   - zmdt_evidence_photos
   - zmdt_department_accounts
   - zmdt_department_transactions

## Step 3: Configure the Resource

1. Open `Z-MDT/shared/config.lua` in a text editor
2. Configure the following settings:

   ### Framework Selection
   ```lua
   Config.Framework = 'qb-core' -- 'qb-core' or 'qbox'
   ```

   ### Integrations
   ```lua
   Config.Integrations = {
       Police = 'wasabi_police', -- Your police job resource
       Ambulance = 'wasabi_ambulance', -- Your ambulance job resource
       Banking = 'okokBanking', -- 'okokBanking', 'qb-banking', 'codm-banking', 'qb-management'
       Dispatch = 'custom', -- 'rcore', 'ps-dispatch', 'custom'
       Inventory = 'qb-inventory', -- 'qb-inventory' or 'ox_inventory'
       Roster = 'fiveroster' -- Set to '' if not using
   }
   ```

   ### Job Permissions
   ```lua
   Config.AuthorizedJobs = {
       ['police'] = {
           grades = {0, 1, 2, 3, 4, 5}, -- Adjust to match your job grades
           permissions = {'view_people', 'view_vehicles', 'create_incidents', 'issue_fines', 'create_warrants', 'view_custody', 'manage_custody'}
       },
       ['ambulance'] = {
           grades = {0, 1, 2, 3, 4}, -- Adjust to match your job grades
           permissions = {'view_people', 'view_medical', 'create_medical_incidents', 'manage_medical_records'}
       }
       -- Add more jobs as needed
   }
   ```

   ### Discord Webhooks (Optional)
   ```lua
   Config.Webhooks = {
       fines = 'https://discord.com/api/webhooks/your_webhook_url',
       incidents = 'https://discord.com/api/webhooks/your_webhook_url',
       warrants = 'https://discord.com/api/webhooks/your_webhook_url',
       custody = 'https://discord.com/api/webhooks/your_webhook_url',
       medical = 'https://discord.com/api/webhooks/your_webhook_url'
   }
   ```

   ### Image Upload for Mugshots
   ```lua
   Config.Mugshot = {
       coords = vector4(402.91665649414, -996.75970458984, -99.000259399414, 186.22036743164),
       camera_coords = vector4(402.91665649414, -995.75970458984, -98.5, 186.22036743164),
       upload_url = 'https://api.imgur.com/3/image', -- Change if using a different service
       upload_headers = {
           ['Authorization'] = 'Client-ID YOUR_IMGUR_CLIENT_ID' -- Replace with your actual API key
       }
   }
   ```

## Step 4: Add Tablet Item

### For QB-Core:
1. Open `qb-core/shared/items.lua`
2. Add the following item:
```lua
['zmdt_tablet'] = {['name'] = 'zmdt_tablet', ['label'] = 'Police Tablet', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'zmdt_tablet.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Mobile Data Terminal for law enforcement'},
```

### For ox_inventory:
The item is automatically registered through the exports in `Z-MDT/shared/items.lua`

## Step 5: Add Item Image

1. Add the tablet image to your inventory resource:
   - For qb-inventory: `qb-inventory/html/images/zmdt_tablet.png`
   - For ox_inventory: `ox_inventory/web/images/zmdt_tablet.png`

2. You can use any tablet image or create your own

## Step 6: Update server.cfg

Add the following line to your server.cfg:
```
ensure Z-MDT
```

## Step 7: Start the Server

1. Restart your FiveM server
2. Check the server console for any errors related to Z-MDT
3. If everything is working correctly, you should see "Z-MDT initialized successfully" in the console

## Step 8: Testing

1. Join your server as a police officer or other authorized job
2. Use the `/openmdt` command or use the tablet item from your inventory
3. The MDT interface should open, showing the dashboard

## Troubleshooting

### Common Issues:

1. **"Script Error: Z-MDT/server/main.lua:XX: attempt to index a nil value"**
   - Check that your framework selection in config.lua matches your server (qb-core or qbox)
   - Ensure oxmysql is properly installed and working

2. **MDT doesn't open when using the tablet item**
   - Check that the item is properly registered in your inventory system
   - Verify that your job and grade have access in the config

3. **Mugshots or evidence photos fail to upload**
   - Check your image upload service configuration
   - Ensure screenshot-basic is installed and working

4. **Database errors**
   - Make sure you imported the SQL file correctly
   - Check that your database connection is working

For additional help, please create an issue on GitHub or join our Discord server.

## Updating

When updating Z-MDT to a new version:

1. Backup your config.lua file
2. Replace the Z-MDT folder with the new version
3. Compare your backed-up config with the new config.lua and merge any changes
4. Check if there are any new SQL updates to apply
5. Restart your server

## Additional Configuration

For advanced configuration options, including:
- Customizing charges and fines
- Setting up Google Sheets integration
- Configuring department accounts
- Customizing UI themes

Please refer to the full documentation in the README.md file.