# Z-MDT System v2.0 - Enhanced QBCore Integration

## 🚀 Features Added/Fixed

### ✅ Critical Issues Fixed
- **Database Integration**: Fixed oxmysql integration with proper sync/async handling
- **UI/Frontend**: Fixed main page data display, search functionality, and completed missing tabs
- **Job/Rank System**: Simplified job detection to PD vs Ambulance (no more grade complications)
- **Report Creation**: Fixed "Make new reports" functionality with proper validation
- **Jail System**: Added complete jail integration with automatic time calculation

### 🆕 New Features
- **Automatic Jail Time Calculation**: Based on charges with guilty plea reductions
- **Enhanced Search**: Improved people and vehicle search with real data
- **Complete UI Overhaul**: Modern, responsive design with all tabs functional
- **Job Simplification**: Easy PD/Ambulance detection without grade complications
- **Comprehensive Dashboard**: Real statistics and activity feed
- **Jail Configuration**: Separate config for jail system with time calculations

## 📋 Installation Steps

### 1. Prerequisites
- QBCore Framework (or QBox)
- oxmysql
- ox_lib (optional but recommended)

### 2. Database Setup
```sql
-- Run the SQL file in your database
-- File: Z-MDT/sql/install.sql
```

### 3. Resource Installation
1. **Download and Extract**: Place the `Z-MDT` folder in your resources directory
2. **Rename Files**: 
   - Rename `fxmanifest_improved.lua` to `fxmanifest.lua`
   - Rename `main_improved.lua` files to `main.lua` (both client and server)
   - Rename `index_improved.html` to `index.html`
   - Rename `config_improved.lua` to `config.lua`

### 4. Configuration
Edit `shared/config.lua` to match your server setup:

```lua
-- Framework Detection
Config.Framework = 'qb-core' -- 'qb-core' or 'qbox'

-- Job Configuration - Simplified!
Config.Jobs = {
    PoliceJobs = {'police', 'sheriff', 'state', 'fbi', 'dea'},
    MedicalJobs = {'ambulance', 'ems', 'doctor'},
    EmergencyJobs = {'dispatch', 'control'}
}
```

### 5. Item Setup
Add to your `qb-core/shared/items.lua`:
```lua
['zmdt_tablet'] = {
    ['name'] = 'zmdt_tablet',
    ['label'] = 'MDT Tablet',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'zmdt_tablet.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Mobile Data Terminal for emergency services'
}
```

### 6. Job Configuration
The system now automatically detects job types:
- **Police Jobs**: Access to all police features
- **Medical Jobs**: Access to medical features
- **No more grade restrictions!**

## 🎯 Key Features Explained

### Job Detection (Simplified)
```lua
-- OLD WAY (complicated):
-- Had to check specific grades for each of 21 ranks

-- NEW WAY (simple):
-- Just checks if you're police OR ambulance
local jobType = hasMDTAccess(job)
-- Returns: 'police', 'ambulance', or false
```

### Jail Time Calculation
```lua
-- Automatic time calculation based on charges
local charges = {{code = 'T003', title = 'Reckless Driving'}}
local time = calculateJailTime(charges, pleaGuilty)
-- Returns: calculated time in seconds with plea reduction
```

### Enhanced Search
- **People Search**: By name or citizen ID
- **Vehicle Search**: By license plate
- **Real Data**: Actually queries your database
- **Auto-creation**: Creates records if not found

## 🔧 Usage Instructions

### For Police Officers
1. **Get Tablet**: Obtain `zmdt_tablet` item or use `/mdt` command
2. **Open MDT**: Use the item or press F6 (configurable)
3. **Search**: Look up people or vehicles
4. **Create Reports**: Incidents, warrants, fines
5. **Jail Players**: Automatic time calculation based on charges

### For Medical Personnel
1. **Access**: Same as police but with medical-specific features
2. **Medical Records**: Create and manage patient records
3. **Emergency Response**: Access to dispatch and custody info

### For Administrators
1. **Admin Tab**: Full system statistics and audit logs
2. **User Management**: Monitor all MDT activity
3. **System Configuration**: Adjust settings as needed

## ⚙️ Configuration Options

### Jail System
```lua
Config.Jail = {
    Enabled = true,
    BaseTimePerCharge = 300, -- 5 minutes per charge
    GuiltyPleaReduction = 0.25, -- 25% reduction
    MaxSentence = 3600, -- 1 hour maximum
    Cells = { -- Jail cell locations
        {id = 1, label = "Cell 1", coords = vector3(460.0, -994.0, 24.9)},
        -- Add more cells as needed
    }
}
```

### Charge Categories
```lua
Config.ChargeCategories = {
    Minor = {'T001', 'T005', 'P001', 'P002'},
    Moderate = {'T002', 'T004', 'P003', 'P004'},
    Serious = {'T003', 'T006', 'T007', 'C001'},
    Major = {'C002', 'C003', 'C004', 'T008'},
    Severe = {'C005', 'C006'}
}
```

### Time Multipliers
```lua
Config.TimeMultipliers = {
    Minor = 1.0,      -- Base time
    Moderate = 1.5,   -- 1.5x base time
    Serious = 2.0,    -- 2x base time
    Major = 3.0,      -- 3x base time
    Severe = 5.0      -- 5x base time
}
```

## 🛠️ Troubleshooting

### Common Issues

1. **"UI not showing data"**
   - Check oxmysql connection
   - Verify database tables exist
   - Check browser console for errors

2. **"Search not working"**
   - Ensure player/vehicle data exists in database
   - Check query syntax in server logs
   - Verify permissions

3. **"Jail system not working"**
   - Check jail configuration
   - Verify jail cells are available
   - Check if player is online

4. **"Job detection not working"**
   - Verify job names in config match your framework
   - Check if player job is set correctly
   - Debug with `/mdt` command

### Debug Mode
Enable debug mode in config:
```lua
Config.System = {
    Debug = true, -- Enable detailed logging
    -- ... other settings
}
```

## 📞 Support

For support and updates:
- Check the GitHub repository
- Review the troubleshooting section
- Enable debug mode for detailed logs
- Check server console for error messages

## 🔄 Updates

This is version 2.0 with major improvements:
- Fixed all critical issues mentioned
- Added comprehensive jail system
- Simplified job detection
- Enhanced UI/UX
- Improved database integration

Future updates will focus on:
- Additional integrations
- Performance optimizations
- New features based on community feedback