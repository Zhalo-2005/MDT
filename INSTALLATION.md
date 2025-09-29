# Z-MDT Enhanced Installation Guide

## Prerequisites

Before installing Z-MDT Enhanced, ensure you have the following:

- **QBCore Framework** (latest version)
- **oxmysql** (for database operations)
- **screenshot-basic** (for mugshot functionality)
- **JG-Dealership** (optional, for vehicle integration)
- **Discord Bot** (optional, for webhook notifications)

## Installation Steps

### 1. Download and Extract

1. Download the Z-MDT Enhanced package
2. Extract the contents to your `resources` folder
3. You should have two main folders:
   - `Z-MDT` - The main MDT system
   - `Z-Evidence` - The evidence management system (separate script)

### 2. Database Setup

1. Import the SQL schema file:
   ```sql
   -- Run this in your database
   source Z-MDT/sql/mdt_schema.sql
   ```

2. The schema will create all necessary tables for:
   - Citizens and profiles
   - Vehicles and registration
   - Incidents and reports
   - Fines and warrants
   - Custody records
   - Evidence management
   - Medical records
   - Financial transactions
   - Audit logs

### 3. Configuration

1. Copy `shared/config_enhanced.lua` to `shared/config.lua` in the Z-MDT folder
2. Edit the configuration file to match your server setup:
   ```lua
   -- Framework settings
   Config.Framework = 'qb-core' -- or 'qbox'
   
   -- Database integration
   Config.Integrations.Dealership = 'jg-dealership' -- Your dealership script
   
   -- Discord webhooks
   Config.Webhooks.fines = 'YOUR_DISCORD_WEBHOOK_URL'
   Config.Webhooks.incidents = 'YOUR_DISCORD_WEBHOOK_URL'
   -- ... add other webhook URLs
   
   -- Government tax settings
   Config.GovernmentTax.tax_rate = 0.10 -- 10% tax on fines
   
   -- Fine payment locations
   Config.FineSystem.payment_locations = {
       {
           coords = vector3(240.06, -1074.73, 29.29),
           label = "Courthouse",
           blip = true
       }
       -- ... add more locations
   }
   ```

### 4. Server Configuration

1. Add to your `server.cfg`:
   ```
   ensure Z-MDT
   ensure Z-Evidence
   ```

2. Configure your jobs in `qb-core/shared/jobs.lua` to include MDT permissions:
   ```lua
   ['police'] = {
       -- ... existing job configuration
       grades = {
           [0] = {
               name = "recruit",
               -- ... add MDT permissions through the system
           }
       }
   }
   ```

### 5. Item Configuration

Add the MDT tablet item to your inventory system:

**For qb-inventory:**
```lua
['zmdt_tablet'] = {
    name = 'zmdt_tablet',
    label = 'MDT Tablet',
    weight = 500,
    type = 'item',
    image = 'zmdt_tablet.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Police Mobile Data Terminal'
}
```

### 6. Discord Integration (Optional)

1. Create a Discord bot and get the token
2. Add the bot to your server
3. Configure webhook URLs in the config file
4. Set up channel permissions for the bot

### 7. Photo Upload Configuration (Optional)

For photo uploads, configure your image hosting service:

**Imgur Setup:**
1. Create an Imgur application
2. Get your Client ID
3. Add to config:
   ```lua
   Config.Media.PhotoUpload = {
       service = 'imgur',
       api_key = 'YOUR_IMGUR_CLIENT_ID',
       max_file_size = 10485760 -- 10MB
   }
   ```

## Post-Installation Setup

### 1. Job Rank Synchronization

The system will automatically sync job ranks from qb-core. To verify:

1. Start your server
2. Check server console for "Z-MDT System initialization complete!"
3. Job ranks should be automatically populated

### 2. Department Accounts

Default department accounts are created automatically:
- Government Account
- Police Department Account
- Sheriff Department Account
- Ambulance Department Account

### 3. Testing

Test the following features:
1. **Tablet Usage**: Use the `zmdt_tablet` item
2. **Person Search**: Search by name, citizen ID, or phone
3. **Vehicle Search**: Search by license plate
4. **Incident Creation**: Create and manage incidents
5. **Fine System**: Issue and pay fines
6. **Evidence System**: Create and manage evidence
7. **Boss Menu**: Access department management
8. **Real-time Updates**: Check for live updates

### 4. Permission Testing

Verify permissions work correctly:
- Recruits can only view basic information
- Officers can create incidents and issue fines
- Sergeants can manage custody
- Lieutenants can access boss features
- Captains have full access

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Ensure oxmysql is properly installed and configured
   - Check database credentials in server.cfg
   - Verify all tables were created successfully

2. **Permission Issues**
   - Check job configuration in qb-core
   - Verify job ranks are properly synced
   - Check server console for permission errors

3. **Real-time Updates Not Working**
   - Ensure client-side scripts are loading properly
   - Check for JavaScript errors in browser console
   - Verify network connectivity

4. **Photos Not Uploading**
   - Check image hosting service configuration
   - Verify API keys are correct
   - Check file size limits

5. **Discord Webhooks Not Working**
   - Verify webhook URLs are correct
   - Check Discord bot permissions
   - Ensure webhook channel exists

### Debug Mode

Enable debug mode in the config:
```lua
Config.Development.debug_mode = true
```

This will provide detailed logging for troubleshooting.

### Performance Issues

If experiencing lag:
1. Reduce `Config.RealTimeUpdates.update_interval`
2. Lower `Config.Performance.MaxDatabaseQueriesPerSecond`
3. Enable caching with `Config.Performance.EnableCaching = true`
4. Reduce `Config.Performance.max_evidence_per_query`

## Support

For support and updates:
- Check the GitHub repository for latest versions
- Report issues on the GitHub issues page
- Join our Discord community for help

## Credits

- **Zhalo-2005** - Original MDT system and enhancements
- **QBCore Team** - Framework foundation
- **Community Contributors** - Testing and feedback

## License

This resource is provided as-is for educational and roleplay purposes. Use at your own risk.