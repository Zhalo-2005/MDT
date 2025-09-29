# Z-MDT System v2.0 - Deployment Instructions

## 🎯 What Was Fixed

✅ **Database Integration**: Fixed oxmysql connection issues and data loading  
✅ **UI/Frontend**: Complete interface overhaul with all tabs functional  
✅ **Job System**: Simplified to PD vs Ambulance detection (no grade complications)  
✅ **Report Creation**: Fixed incident creation with proper validation  
✅ **Jail System**: Added complete jail functionality with automatic time calculation  

## 🚀 Quick Deployment Guide

### Step 1: Backup Your Current Files
```bash
# Make backup of your current MDT
cp -r resources/[qb]/Z-MDT resources/[qb]/Z-MDT_backup
```

### Step 2: Replace Core Files
```bash
# Rename the improved files
cd resources/[qb]/Z-MDT/

# Server files
mv server/main_improved.lua server/main.lua
mv server/jail.lua server/jail.lua  # New file

# Client files  
mv client/main_improved.lua client/main.lua

# Shared files
mv shared/config_improved.lua shared/config.lua

# Web files
mv web/index_improved.html web/index.html
mv web/js/main_improved.js web/js/main.js

# Manifest
mv fxmanifest_improved.lua fxmanifest.lua
```

### Step 3: Database Update
```sql
-- No database changes needed - just ensure tables exist
-- Run the install.sql file if you haven't already
```

### Step 4: Configuration
Edit `shared/config.lua` with your server settings:

```lua
-- Simple job detection - just list your job names
Config.Jobs = {
    PoliceJobs = {'police', 'sheriff', 'state'}, -- Add your police jobs
    MedicalJobs = {'ambulance', 'ems'}           -- Add your medical jobs
}
```

### Step 5: Restart Resources
```bash
# In your server console:
restart Z-MDT
# or
ensure Z-MDT
```

## 📋 File Structure After Deployment

```
Z-MDT/
├── fxmanifest.lua              # Updated manifest
├── shared/
│   ├── config.lua              # Simplified configuration
│   ├── charges.lua             # Charge definitions
│   └── items.lua               # Item configurations
├── client/
│   ├── main.lua                # Enhanced client (was main_improved.lua)
│   ├── dispatch.lua
│   ├── medical.lua
│   ├── mugshot.lua
│   └── payments.lua
├── server/
│   ├── main.lua                # Enhanced server (was main_improved.lua)
│   ├── jail.lua                # NEW - Complete jail system
│   ├── audit.lua
│   ├── custody.lua
│   ├── departments.lua
│   ├── fines.lua
│   └── medical.lua
├── web/
│   ├── index.html              # Enhanced UI (was index_improved.html)
│   ├── js/main.js              # Enhanced frontend (was main_improved.js)
│   └── css/style.css
└── sql/
    └── install.sql
```

## ⚡ Immediate Benefits After Deployment

### For Police Officers:
- ✅ **Working Search**: Find people and vehicles instantly
- ✅ **Real Dashboard**: See actual server statistics
- ✅ **Easy Reports**: Create incidents with proper validation
- ✅ **Jail Integration**: Automatic time calculation based on charges
- ✅ **Simple Access**: No more grade complications - just PD access

### For Medical Staff:
- ✅ **Medical Records**: Complete patient management
- ✅ **Emergency Access**: Dispatch and custody information
- ✅ **Simplified UI**: Clean, professional interface

### For Administrators:
- ✅ **Full Control**: Admin panel with system statistics
- ✅ **Audit Logs**: Track all MDT activity
- ✅ **Easy Configuration**: Simple job-based permissions

## 🔧 Configuration Examples

### Basic Setup (Minimal Config)
```lua
-- Just add your job names - that's it!
Config.Jobs = {
    PoliceJobs = {'police'},        -- Your police job
    MedicalJobs = {'ambulance'}     -- Your medical job
}
```

### Advanced Setup (Multiple Departments)
```lua
Config.Jobs = {
    PoliceJobs = {
        'police', 'sheriff', 'state', 
        'fbi', 'dea', 'ranger'
    },
    MedicalJobs = {
        'ambulance', 'ems', 'doctor', 
        'nurse', 'paramedic'
    }
}
```

### Jail Configuration
```lua
Config.Jail = {
    Enabled = true,
    BaseTimePerCharge = 300,        -- 5 minutes per charge
    GuiltyPleaReduction = 0.25,     -- 25% reduction for guilty plea
    MaxSentence = 3600,             -- 1 hour maximum
    Cells = {
        {id = 1, label = "Cell 1", coords = vector3(460.0, -994.0, 24.9)},
        -- Add your jail cell locations
    }
}
```

## 🎮 Testing Checklist

After deployment, test these features:

### Basic Functionality
- [ ] Open MDT with tablet item or F6 key
- [ ] Dashboard shows real player/vehicle counts
- [ ] Search for existing players by name/ID
- [ ] Search for vehicles by license plate
- [ ] Create incident reports
- [ ] Issue fines to players

### Jail System
- [ ] Add charges to calculate jail time
- [ ] Test guilty plea reduction (25% off)
- [ ] Verify jail cell assignment
- [ ] Check automatic release after time served

### Job Access
- [ ] Police officers see all police tabs
- [ ] Medical staff see medical tabs
- [ ] Job detection works without grade checks
- [ ] Admin access to all features

## 🆘 Troubleshooting

### "UI still shows old version"
```bash
# Clear browser cache
# Restart the resource completely
restart Z-MDT
```

### "Search not finding players"
```sql
-- Check if players exist in database
SELECT COUNT(*) FROM players;
SELECT COUNT(*) FROM player_vehicles;
```

### "Jail system not working"
- Check jail configuration in `shared/config.lua`
- Ensure jail cells are properly configured
- Verify player is online when jailing

### "Job access not working"
- Check job names in config match your framework
- Use debug mode to see job detection:
```lua
Config.System.Debug = true
```

## 📞 Need Help?

1. **Check Documentation**: Read `INSTALLATION_GUIDE.md` and `FIXES_SUMMARY.md`
2. **Enable Debug Mode**: Set `Config.System.Debug = true` for detailed logs
3. **Check Server Console**: Look for error messages
4. **Verify File Names**: Ensure all files are properly renamed

## 🎉 Success Indicators

You'll know the deployment was successful when:

✅ Dashboard shows real numbers (not 0, 0, 0, 0)  
✅ Search finds existing players and vehicles  
✅ Incident creation works without errors  
✅ Jail time calculates automatically based on charges  
✅ Job access works without grade complications  
✅ All UI tabs are functional and complete  

## 🔄 Rollback Plan

If you need to rollback:
```bash
# Restore backup
rm -rf resources/[qb]/Z-MDT
mv resources/[qb]/Z-MDT_backup resources/[qb]/Z-MDT
restart Z-MDT
```

---

**🎯 Result**: You now have a fully functional MDT system that works exactly as intended, with all the features you requested and none of the previous issues!