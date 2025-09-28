# Z-MDT - UK-Based Police Mobile Data Terminal

Z-MDT is a comprehensive Mobile Data Terminal system for FiveM servers, specifically designed with UK police and emergency services in mind. It provides a modern, feature-rich interface for law enforcement and medical personnel to manage citizens, vehicles, incidents, warrants, custody records, and more.

## Features

### Core Features
- **People & Vehicles Database**: Search and manage citizen records and vehicle registrations
- **Incidents & Reports**: Create and track police incidents with detailed information
- **Warrants System**: Issue and manage arrest warrants
- **Custody Records**: Book suspects into custody and manage cell assignments
- **Fines System**: Issue fines with configurable charges and penalty points
- **NHS Medical Records**: Track patient medical history and add medical flags
- **Dispatch Integration**: Built-in dispatch system with external integrations
- **Mugshot Camera**: Take and store mugshots for citizen records
- **Evidence Photos**: Attach photos to incident reports

### Technical Features
- **Framework Support**: Works with QB-Core and QBox
- **Inventory Integration**: Supports ox_inventory and qb-inventory
- **Banking Integration**: Compatible with okokBanking, qb-banking, codm-banking, and qb-management
- **Dispatch Integration**: Works with rCore, ps-dispatch, or the built-in system
- **Discord Webhooks**: Send notifications for fines, incidents, warrants, custody, and medical records
- **Google Sheets Integration**: Export data to Google Sheets
- **FiveRoster Support**: Sync officer status with FiveRoster
- **Audit Logging**: Track all actions for accountability
- **Department Accounts**: Manage department finances

## Installation

### Requirements
- QB-Core or QBox framework
- oxmysql
- screenshot-basic (for mugshots and evidence photos)
- ox_lib (recommended for enhanced UI elements)

### Setup Instructions

1. **Download & Extract**
   - Download the latest release
   - Extract the Z-MDT folder to your server's resources directory

2. **Database Setup**
   - Import the SQL file located in `Z-MDT/sql/install.sql` to your database

3. **Configuration**
   - Edit `Z-MDT/shared/config.lua` to match your server's setup
   - Configure webhooks, job permissions, and other settings

4. **Item Setup**
   - Add the tablet item to your server's items
   - For QB-Core, add to `qb-core/shared/items.lua`:
     ```lua
     ['zmdt_tablet'] = {['name'] = 'zmdt_tablet', ['label'] = 'Police Tablet', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'zmdt_tablet.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Mobile Data Terminal for law enforcement'},
     ```
   - For ox_inventory, the item is automatically registered

5. **Add to server.cfg**
   ```
   ensure Z-MDT
   ```

6. **Image Upload Setup**
   - For mugshots and evidence photos, you need an image upload service
   - Edit the `Config.Mugshot.upload_url` and `Config.Mugshot.upload_headers` in config.lua
   - Recommended: Set up an Imgur API key (https://api.imgur.com)

## Usage

### Accessing the MDT
- Use the `zmdt_tablet` item from your inventory
- Alternatively, use the `/openmdt` command (if enabled)

### Permissions
- Configure which jobs and grades have access in the config file
- Set specific permissions for different actions (view records, issue fines, etc.)

### Features Guide

#### People Management
- Search citizens by name or ID
- View and update personal information
- See criminal history, fines, and warrants
- Take mugshots
- Add notes and flags

#### Vehicle Management
- Search vehicles by plate
- View and update vehicle information
- Mark vehicles as stolen or impounded
- See vehicle history

#### Incidents
- Create detailed incident reports
- Attach citizens and vehicles to incidents
- Add evidence photos
- Update incident status

#### Warrants
- Issue arrest warrants with charges
- Set bail amounts
- Execute or cancel warrants

#### Fines
- Issue fines with configurable charges
- Apply penalty points for driving offenses
- Set payment locations
- Track payment status

#### Custody
- Book suspects into custody
- Assign cells
- Set custody time and bail amounts
- Process releases

#### Medical Records (NHS)
- Create medical records for citizens
- Add medical flags (allergies, conditions)
- Track treatment history

#### Dispatch
- Create and manage dispatch calls
- Assign units to calls
- Update call status
- Set GPS waypoints

## Configuration Options

The config.lua file contains extensive options for customizing Z-MDT:

- Framework selection (QB-Core or QBox)
- Integration settings for banking, dispatch, etc.
- Job permissions and access levels
- Webhook URLs for Discord notifications
- Google Sheets integration
- Banking settings
- Blip configurations
- Mugshot camera settings
- Fine payment locations
- Medical flags
- Custody cell locations
- Department accounts
- Audit log settings
- UI themes

## Support

For support, bug reports, or feature requests:
- GitHub Issues: [Create an issue](https://github.com/Zhalo-2005/MDT/issues)
- Discord: [Join our Discord](https://discord.gg/yourdiscord)

## Credits

- Developed by Zhalo-2005
- Special thanks to the QB-Core community