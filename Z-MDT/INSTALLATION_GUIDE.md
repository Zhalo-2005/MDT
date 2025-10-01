# Z-MDT Tablet Installation Guide

## 🎯 Overview
This guide will help you install the Z-MDT system as a tablet-based MDT for your FiveM server.

## 📁 Files Structure
```
Z-MDT/
├── client/
│   ├── main.lua          # Tablet client script
│   ├── jail.lua          # Jail system client
│   └── fines.lua         # Fines system client
├── server/
│   ├── main.lua          # Main server logic
│   ├── jail.lua          # Jail system server
│   └── fines.lua         # Fines system server
├── shared/
│   ├── config.lua        # Configuration file
│   └── locales.lua       # Language file
├── web/
│   ├── index.html        # Main UI
│   ├── css/
│   │   └── zmdt-style.css # Styling
│   ├── js/
│   │   └── zmdt-main.js  # UI functionality
│   └── images/           # UI assets
├── items.lua             # Tablet item configuration
├── fxmanifest.lua        # Resource manifest
└── sql/                  # Database setup
```

## 🔧 Installation Steps

### 1. Resource Setup
1. Copy the entire `Z-MDT` folder to your server's `resources/` directory
2. Add to your server.cfg:
```
ensure Z-MDT
```

### 2. Database Setup
Run the SQL files in the `sql/` directory in order:
```sql
-- Run zmdt_tables.sql first
-- Then run zmdt_indexes.sql
```

### 3. Tablet Item Setup

#### Option A: Add to qb-core/shared/items.lua
```lua
['zmdt_tablet'] = {
    name = 'zmdt_tablet',
    label = 'Police Tablet',
    weight = 500,
    type = 'item',
    image = 'tablet.png',
    unique = true,
    useable = true,
    description = 'A police tablet for accessing the MDT system',
    shouldClose = true,
    combinable = nil
}
```

#### Option B: Use the provided items.lua
The `items.lua` file is automatically loaded if you use the provided structure.

### 4. Job Configuration
Edit `shared/config.lua` to configure which jobs can access the MDT:

```lua
Config.AuthorizedJobs = {
    ['police'] = {
        label = 'Police Department',
        grades = {0, 1, 2, 3, 4}, -- All grades
        actions = {
            'view_mdt',
            'create_reports',
            'issue_fines',
            'view_fines',
            'create_bolos',
            'jail_players',
            'view_jail'
        }
    },
    ['ambulance'] = {
        label = 'Emergency Medical Services',
        grades = {0, 1, 2, 3, 4}, -- All grades
        actions = {
            'view_mdt',
            'create_reports',
            'view_incidents'
        }
    }
}
```

### 5. Key Configuration
By default, the tablet opens with F6 key. You can change this in `shared/config.lua`:
```lua
Config.DefaultKey = 'F6'
```

### 6. Banking Integration
Configure your banking system in `shared/config.lua`:
```lua
Config.Integrations.Banking = 'qb-management' -- Options: 'okokBanking', 'qb-banking', 'codm-banking', 'qb-management'
```

## 🎮 Usage

### For Players
1. Obtain the `zmdt_tablet` item
2. Use the item or press F6 to open
3. Navigate through tabs using the interface

### For Admins
1. Give the tablet item:
```
/giveitem [playerid] zmdt_tablet 1
```

## 🔍 Features

### Tablet Features
- ✅ **Physical tablet prop** appears in hand
- ✅ **Tablet animation** when opening
- ✅ **Job-based access** (Police/Ambulance only)
- ✅ **Key binding** support (F6 default)
- ✅ **Item-based usage** with `zmdt_tablet`

### MDT Features
- ✅ **Dashboard** with real-time stats
- ✅ **Citizen search** with detailed profiles
- ✅ **Vehicle search** with ownership info
- ✅ **Fine system** with automatic calculation
- ✅ **Jail system** with time calculation
- ✅ **Report creation** with evidence
- ✅ **BOLO system** for alerts

## 🚨 Troubleshooting

### Common Issues

#### Tablet Not Opening
1. Check job permissions in config.lua
2. Ensure player has the zmdt_tablet item
3. Check console for errors

#### UI Not Responding
1. Check browser console (F12) for JavaScript errors
2. Ensure all files are properly uploaded
3. Restart the resource: `restart Z-MDT`

#### Database Errors
1. Ensure oxmysql is running
2. Check database connection
3. Verify all SQL tables are created

### Debug Mode
Enable debug mode in config.lua:
```lua
Config.Debug = true
```

Then use `/zmdt:debug` command to check configuration.

## 📱 Tablet Commands

### Client Commands
- `/zmdt` - Open MDT (if key binding fails)
- `/zmdt:debug` - Show debug info

### Server Commands
- `giveitem [playerid] zmdt_tablet 1` - Give tablet to player

## 🎨 Customization

### Themes
Three built-in themes available:
- Purple/Blue (default)
- Dark Red
- Ocean Blue

### UI Customization
Edit `web/css/zmdt-style.css` to customize appearance.

## 🔗 Dependencies
- **Required**: qb-core, oxmysql, ox_lib
- **Optional**: okokBanking, qb-banking, qb-management, codm-banking

## ✅ Verification Checklist
- [ ] Resource starts without errors
- [ ] Tablet item is creatable
- [ ] MDT opens with F6 key
- [ ] MDT opens with tablet item
- [ ] Job restrictions work correctly
- [ ] All tabs are functional
- [ ] Fines system works
- [ ] Jail system works
- [ ] Database saves properly
- [ ] UI is responsive

## 📞 Support
For support, check the GitHub issues or contact the development team.