# Z-MDT Enhanced 🚔

The most advanced and comprehensive Police Mobile Data Terminal system for QBCore, featuring real-time updates, evidence management, financial systems, and much more.

## ✨ Features

### 🎯 Core MDT Functionality
- **Modern UI/UX** - Sleek, responsive interface with animations
- **Real-time Updates** - Live data synchronization across all connected units
- **Advanced Search** - Search people, vehicles, incidents with filters
- **Multi-department Support** - Police, Sheriff, EMS, FIB integration
- **Responsive Design** - Works on all screen sizes

### 👥 People Management
- **Comprehensive Profiles** - Detailed citizen information including photos, fingerprints, DNA
- **Criminal Records** - Track criminal history and risk levels
- **Medical Records** - Allergies, conditions, emergency contacts
- **Real-time Status** - See who's online and their current status
- **Advanced Filtering** - Filter by risk level, criminal record, demographics

### 🚗 Vehicle Integration
- **JG-Dealership Integration** - Direct connection to vehicle ownership
- **Registration Tracking** - Monitor registration status and expiry
- **Insurance Verification** - Check insurance status and details
- **Theft/Impound System** - Track stolen and impounded vehicles
- **Service History** - Maintenance and repair records

### 📋 Incident Management
- **Rich Incident Creation** - Photos, videos, evidence attachments
- **Environmental Conditions** - Weather, lighting, road conditions
- **Involved Parties** - Citizens, vehicles, officers, witnesses
- **Priority System** - Critical, high, medium, low priority levels
- **Status Tracking** - Pending, active, resolved, closed statuses

### ⚖️ Legal System
- **Charge Selection** - Pre-configured charges with fines and points
- **Fine Calculation** - Automatic fine calculation with payment plans
- **Government Tax System** - Configurable tax rates (default 10%)
- **Warrant Management** - Create and track active warrants
- **Custody System** - Complete custody management with jail time

### 💰 Financial System
- **Department Accounts** - Separate accounts for each department
- **Transaction Tracking** - Complete financial audit trail
- **Tax Distribution** - Automatic government tax collection
- **Payment Locations** - Multiple fine payment locations
- **Payment Plans** - Installment options for large fines

### 🧬 Evidence System (Separate Script)
- **Advanced Evidence Management** - Categorize and store all evidence types
- **Chain of Custody** - Complete audit trail for evidence handling
- **Analysis System** - DNA, fingerprint, drug, ballistics analysis
- **Secure Storage** - Multiple storage locations with access controls
- **Disposition Management** - Legal disposal of evidence

### 👮 Boss Menu
- **Employee Management** - View and manage department employees
- **Financial Oversight** - Department budget and transaction monitoring
- **Statistics Dashboard** - Comprehensive department statistics
- **Rank Management** - Promote/demote officers
- **Announcement System** - Department-wide communications

### 🤖 Discord Integration
- **Webhook Notifications** - Real-time Discord notifications
- **Bot Integration** - Automated Discord bot responses
- **Multi-channel Support** - Different channels for different notifications
- **Rich Embeds** - Detailed Discord embeds with all information

### 📊 Reports & Analytics
- **Department Statistics** - Crime rates, officer performance, financial data
- **Custom Reports** - Generate custom reports with filters
- **Data Export** - Export data in multiple formats
- **Charts & Graphs** - Visual representation of data
- **Historical Analysis** - Track trends over time

### 🔒 Security & Permissions
- **Rank-based Access** - Granular permission system based on job grades
- **Audit Logging** - Complete audit trail of all actions
- **Security Classifications** - Classified evidence handling
- **Session Management** - Secure session handling
- **IP Whitelisting** - Optional IP restriction

### ⚡ Performance Optimization
- **Efficient Caching** - Smart caching system for optimal performance
- **Database Optimization** - Indexed queries and connection pooling
- **Real-time Updates** - Batched updates to prevent server lag
- **Resource Management** - Minimal resource usage
- **Scalable Architecture** - Handles high player counts

## 🚀 Installation

### Prerequisites
- QBCore Framework (latest version)
- oxmysql (for database operations)
- screenshot-basic (for mugshot functionality)
- JG-Dealership (optional, for vehicle integration)

### Quick Install
1. Download the latest release
2. Extract to your `resources` folder
3. Import the SQL schema: `Z-MDT/sql/mdt_schema.sql`
4. Configure `shared/config.lua` with your settings
5. Add to server.cfg: `ensure Z-MDT` and `ensure Z-Evidence`
6. Restart your server

### Detailed Installation
See [INSTALLATION.md](INSTALLATION.md) for complete installation instructions.

## 📖 Documentation

### API Documentation
Comprehensive API documentation available in [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

### Configuration Guide
All configuration options explained in the config file with detailed comments.

## 🎨 Customization

### Themes
Built-in themes for different departments:
- Police Theme (default)
- Sheriff Theme
- EMS Theme
- FIB Theme

### Custom Themes
Create your own themes by modifying the CSS variables in the config.

### Webhooks
Full Discord webhook support with customizable embeds and notifications.

## 🔧 Configuration

### Key Configuration Options
```lua
-- Government Tax
Config.GovernmentTax.tax_rate = 0.10 -- 10% tax on fines

-- Real-time Updates
Config.RealTimeUpdates.update_interval = 1000 -- 1 second

-- Evidence System
Config.EvidenceSystem.enabled = true
Config.EvidenceSystem.max_storage_time = 2592000 -- 30 days

-- Performance
Config.Performance.MaxDatabaseQueriesPerSecond = 100
Config.Performance.EnableCaching = true
```

## 🐛 Troubleshooting

### Common Issues
1. **Database Connection** - Ensure oxmysql is properly configured
2. **Permissions** - Check job configuration in qb-core
3. **Real-time Updates** - Verify client-side script loading
4. **Photos Not Uploading** - Check image hosting service configuration

### Debug Mode
Enable debug mode for detailed logging:
```lua
Config.Development.debug_mode = true
```

## 📈 Performance

### Optimization Features
- Smart caching system
- Database query optimization
- Real-time update batching
- Resource usage monitoring
- Automatic cleanup routines

### Benchmarks
- Supports 100+ concurrent users
- Sub-second response times
- Minimal server impact
- Efficient memory usage

## 🤝 Support

### Getting Help
- 📋 **GitHub Issues** - Report bugs and request features
- 💬 **Discord Community** - Get help from other users
- 📖 **Documentation** - Comprehensive guides and API docs

### Updates
- Regular updates with new features
- Bug fixes and performance improvements
- Community-requested features
- Security updates

## 🏆 Credits

### Development Team
- **Zhalo-2005** - Lead Developer & Designer
- **QBCore Team** - Framework Foundation
- **Community Contributors** - Testing, feedback, and suggestions

### Special Thanks
- JG Scripts for dealership integration
- The FiveM community for support
- All beta testers and contributors

## 📄 License

This resource is provided for educational and roleplay purposes. Use at your own risk. Please respect the work and don't redistribute without permission.

## 🌟 Features in Development

### Coming Soon
- 🌐 **Web Interface** - Access MDT through web browser
- 📱 **Mobile App** - Mobile companion app
- 🤖 **AI Integration** - Smart suggestions and analysis
- 🔗 **Third-party Integrations** - More script compatibility
- 📊 **Advanced Analytics** - Machine learning insights

---
**Transform your law enforcement roleplay with the most advanced MDT system available!** 🚔✨
