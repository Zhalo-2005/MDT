# Z-MDT Enhanced API Documentation

## Overview

This document provides comprehensive API documentation for the Z-MDT Enhanced system, including server exports, client exports, events, and database structures.

## Server Exports

### MDT System Exports

#### `LogAction(source, action, details)`
Logs an action to the audit system.

**Parameters:**
- `source` (number): Player server ID
- `action` (string): Action type (e.g., 'CREATE_INCIDENT', 'ISSUE_FINE')
- `details` (string): Action details/description

**Returns:** Boolean (success)

**Example:**
```lua
exports['z-mdt']:LogAction(source, 'CREATE_INCIDENT', 'Created incident: INC-123456')
```

#### `SendWebhook(type, data)`
Sends a webhook notification to Discord.

**Parameters:**
- `type` (string): Webhook type ('fines', 'incidents', 'warrants', etc.)
- `data` (table): Data to send in webhook

**Returns:** Boolean (success)

**Example:**
```lua
exports['z-mdt']:SendWebhook('fines', {
    title = 'Fine Issued',
    citizenid = 'ABC123',
    amount = 1000,
    officer = 'John Doe'
})
```

#### `ProcessFinancialTransaction(data)`
Processes a financial transaction with government tax.

**Parameters:**
- `data` (table): Transaction data

**Returns:** Boolean (success)

**Example:**
```lua
exports['z-mdt']:ProcessFinancialTransaction({
    type = 'fine_payment',
    amount = 1000,
    government_tax = 100,
    pd_amount = 900,
    citizenid = 'ABC123'
})
```

#### `UpdateRealTimeData(type, data)`
Sends real-time update to all connected MDT clients.

**Parameters:**
- `type` (string): Update type
- `data` (table): Update data

**Returns:** Boolean (success)

**Example:**
```lua
exports['z-mdt']:UpdateRealTimeData('incident_created', {
    incident_id = 'INC-123456',
    data = incidentData
})
```

### Evidence System Exports

#### `CreateEvidence(data)`
Creates new evidence entry.

**Parameters:**
- `data` (table): Evidence data

**Returns:** Table {success, evidence_id, message}

**Example:**
```lua
local result = exports['z-evidence']:CreateEvidence({
    evidence_type = 'physical',
    description = 'Found weapon',
    storage_location = 'LSPD Evidence Locker',
    case_id = 'CASE-123'
})
```

#### `GetEvidence(evidenceId)`
Retrieves evidence information.

**Parameters:**
- `evidenceId` (string): Evidence ID

**Returns:** Table (evidence data)

**Example:**
```lua
local evidence = exports['z-evidence']:GetEvidence('EVI-123456')
```

#### `UpdateEvidence(evidenceId, data)`
Updates existing evidence.

**Parameters:**
- `evidenceId` (string): Evidence ID
- `data` (table): Update data

**Returns:** Boolean (success)

**Example:**
```lua
exports['z-evidence']:UpdateEvidence('EVI-123456', {
    analysis_status = 'completed',
    analysis_results = {dna_match = true}
})
```

#### `CheckEvidenceAccess(src, permission)`
Checks if player has evidence access.

**Parameters:**
- `src` (number): Player server ID
- `permission` (string): Permission to check

**Returns:** Boolean (has access)

**Example:**
```lua
local hasAccess = exports['z-evidence']:CheckEvidenceAccess(source, 'create_evidence')
```

#### `GetEvidenceChain(evidenceId)`
Gets chain of custody for evidence.

**Parameters:**
- `evidenceId` (string): Evidence ID

**Returns:** Table (custody chain entries)

**Example:**
```lua
local chain = exports['z-evidence']:GetEvidenceChain('EVI-123456')
```

## Client Events

### MDT System Events

#### `zmdt:client:useTablet`
Opens the MDT tablet interface.

**Example:**
```lua
TriggerEvent('zmdt:client:useTablet')
```

#### `zmdt:client:createFineBlip`
Creates a fine payment blip on the map.

**Parameters:**
- `coords` (vector3): Blip coordinates
- `fineId` (string): Fine ID

**Example:**
```lua
TriggerEvent('zmdt:client:createFineBlip', vector3(240.06, -1074.73, 29.29), 'FINE-123456')
```

#### `zmdt:client:removeFineBlip`
Removes a fine payment blip.

**Parameters:**
- `fineId` (string): Fine ID

**Example:**
```lua
TriggerEvent('zmdt:client:removeFineBlip', 'FINE-123456')
```

#### `zmdt:client:notification`
Shows a notification in the MDT.

**Parameters:**
- `type` (string): Notification type
- `data` (table): Notification data

**Example:**
```lua
TriggerEvent('zmdt:client:notification', 'evidence_created', {
    evidence_id = 'EVI-123456',
    description = 'Weapon found'
})
```

### Evidence System Events

#### `z-evidence:client:openStorage`
Opens evidence storage interface.

**Parameters:**
- `locationName` (string): Storage location name

**Example:**
```lua
TriggerEvent('z-evidence:client:openStorage', 'LSPD Evidence Locker')
```

#### `z-evidence:client:notification`
Shows evidence system notification.

**Parameters:**
- `type` (string): Notification type
- `data` (table): Notification data

**Example:**
```lua
TriggerEvent('z-evidence:client:notification', 'analysis_complete', {
    evidence_id = 'EVI-123456',
    results = {dna_match = true}
})
```

## Server Events

### MDT System Events

#### `zmdt:server:createIncident`
Creates a new incident.

**Parameters:**
- `data` (table): Incident data

**Example:**
```lua
TriggerServerEvent('zmdt:server:createIncident', {
    title = 'Robbery Report',
    description = 'Suspect fled scene',
    location = 'Vinewood Blvd',
    priority = 'high',
    type = 'police'
})
```

#### `zmdt:server:issueFine`
Issues a fine to a citizen.

**Parameters:**
- `data` (table): Fine data

**Example:**
```lua
TriggerServerEvent('zmdt:server:issueFine', {
    citizenid = 'ABC123',
    charges = {
        {name = 'Speeding', fine = 500, points = 3}
    }
})
```

#### `zmdt:server:payFine`
Processes fine payment.

**Parameters:**
- `fineId` (string): Fine ID

**Example:**
```lua
TriggerServerEvent('zmdt:server:payFine', 'FINE-123456')
```

#### `zmdt:server:createWarrant`
Creates a new warrant.

**Parameters:**
- `data` (table): Warrant data

**Example:**
```lua
TriggerServerEvent('zmdt:server:createWarrant', {
    citizenid = 'ABC123',
    charges = {'Robbery', 'Assault'},
    description = 'Suspect in armed robbery',
    bail_amount = 50000
})
```

#### `zmdt:server:createCustody`
Creates custody record.

**Parameters:**
- `data` (table): Custody data

**Example:**
```lua
TriggerServerEvent('zmdt:server:createCustody', {
    targetId = targetPlayerId,
    charges = {'Possession', 'Resisting Arrest'},
    custody_time = 1800,
    bail_amount = 10000
})
```

### Evidence System Events

#### `z-evidence:server:createEvidence`
Creates new evidence.

**Parameters:**
- `data` (table): Evidence data

**Example:**
```lua
TriggerServerEvent('z-evidence:server:createEvidence', {
    evidence_type = 'physical',
    description = 'Found weapon',
    storage_location = 'LSPD Evidence Locker',
    case_id = 'CASE-123'
})
```

#### `z-evidence:server:updateEvidence`
Updates evidence information.

**Parameters:**
- `data` (table): Update data

**Example:**
```lua
TriggerServerEvent('z-evidence:server:updateEvidence', {
    evidence_id = 'EVI-123456',
    description = 'Updated description',
    analysis_status = 'completed'
})
```

#### `z-evidence:server:transferEvidence`
Transfers evidence to new location.

**Parameters:**
- `data` (table): Transfer data

**Example:**
```lua
TriggerServerEvent('z-evidence:server:transferEvidence', {
    evidence_id = 'EVI-123456',
    new_storage_location = 'Federal Evidence Vault',
    reason = 'High-profile case'
})
```

#### `z-evidence:server:analyzeEvidence`
Submits evidence for analysis.

**Parameters:**
- `data` (table): Analysis data

**Example:**
```lua
TriggerServerEvent('z-evidence:server:analyzeEvidence', {
    evidence_id = 'EVI-123456',
    analysis_type = 'dna'
})
```

#### `z-evidence:server:disposeEvidence`
Disposes of evidence.

**Parameters:**
- `data` (table): Disposition data

**Example:**
```lua
TriggerServerEvent('z-evidence:server:disposeEvidence', {
    evidence_id = 'EVI-123456',
    disposition = 'destroyed',
    reason = 'Case closed, evidence no longer needed'
})
```

## Callbacks

### MDT System Callbacks

#### `zmdt:server:getMDTData`
Gets initial MDT data for player.

**Returns:** Table (MDT data)

**Example:**
```lua
QBCore.Functions.TriggerCallback('zmdt:server:getMDTData', function(data)
    -- Process MDT data
    print(json.encode(data))
end)
```

#### `zmdt:server:searchPerson`
Searches for a person.

**Parameters:**
- `query` (string): Search query

**Returns:** Table (search results)

**Example:**
```lua
QBCore.Functions.TriggerCallback('zmdt:server:searchPerson', function(results)
    if results.success then
        -- Display person data
        print(results.data.firstname)
    end
end, 'John Doe')
```

#### `zmdt:server:searchVehicle`
Searches for a vehicle.

**Parameters:**
- `query` (string): Search query

**Returns:** Table (search results)

**Example:**
```lua
QBCore.Functions.TriggerCallback('zmdt:server:searchVehicle', function(results)
    if results.success then
        -- Display vehicle data
        print(results.data.plate)
    end
end, 'ABC123')
```

### Evidence System Callbacks

#### `z-evidence:server:getEvidence`
Gets evidence information.

**Parameters:**
- `evidenceId` (string): Evidence ID

**Returns:** Table (evidence data)

**Example:**
```lua
QBCore.Functions.TriggerCallback('z-evidence:server:getEvidence', function(results)
    if results.success then
        -- Display evidence data
        print(results.data.description)
    end
end, 'EVI-123456')
```

#### `z-evidence:server:getEvidenceByCase`
Gets all evidence for a case.

**Parameters:**
- `caseId` (string): Case ID

**Returns:** Table (evidence list)

**Example:**
```lua
QBCore.Functions.TriggerCallback('z-evidence:server:getEvidenceByCase', function(results)
    if results.success then
        -- Display evidence list
        for _, evidence in pairs(results.data) do
            print(evidence.description)
        end
    end
end, 'CASE-123')
```

#### `z-evidence:server:getStorageLocations`
Gets accessible storage locations.

**Returns:** Table (storage locations)

**Example:**
```lua
QBCore.Functions.TriggerCallback('z-evidence:server:getStorageLocations', function(results)
    if results.success then
        -- Display storage locations
        for _, location in pairs(results.data) do
            print(location.name)
        end
    end
end)
```

## Database Tables

### Core Tables

#### `zmdt_citizens`
Stores citizen information and profiles.

**Columns:**
- `id`, `citizenid`, `firstname`, `lastname`, `dob`, `phone`, `email`
- `address`, `gender`, `height`, `eye_color`, `hair_color`, `ethnicity`
- `occupation`, `employer`, `marital_status`, `nationality`
- `passport_number`, `driver_license`, `gun_license`
- `medical_notes`, `allergies`, `emergency_contact`
- `photo_url`, `mugshot_url`, `fingerprint_data`, `dna_profile`
- `penalty_points`, `criminal_record`, `risk_level`
- `gang_affiliation`, `known_associates`, `notes`
- `created_at`, `updated_at`

#### `zmdt_vehicles`
Stores vehicle information and registration.

**Columns:**
- `id`, `plate`, `vin`, `model`, `make`, `year`, `color`
- `owner`, `co_owner`, `registration_status`, `registration_expiry`
- `insurance_status`, `insurance_company`, `insurance_policy`
- `vehicle_type`, `weight_class`, `engine_size`, `fuel_type`
- `mileage`, `purchase_date`, `purchase_price`, `current_value`
- `loan_status`, `loan_company`, `stolen`, `stolen_date`
- `impounded`, `impound_date`, `impound_location`, `impound_reason`
- `wanted_level`, `wanted_reason`, `modifications`, `notes`
- `photo_url`, `created_at`, `updated_at`

#### `zmdt_incidents`
Stores incident reports and details.

**Columns:**
- `id`, `incident_id`, `title`, `description`, `location`, `coords`
- `officer_id`, `officer_name`, `backup_officers`, `priority`, `type`
- `category`, `status`, `involved_citizens`, `involved_vehicles`
- `involved_officers`, `witnesses`, `evidence`, `photos`, `videos`
- `audio_recordings`, `documents`, `tags`, `related_incidents`
- `weather_conditions`, `lighting_conditions`, `road_conditions`
- `injuries_reported`, `fatalities`, `property_damage`, `estimated_cost`
- `insurance_claim`, `court_case`, `case_number`, `prosecutor`
- `defense_attorney`, `judge`, `verdict`, `sentence`, `appeal_status`
- `created_at`, `updated_at`, `closed_at`, `closed_by`

#### `zmdt_fines`
Stores fine information and payment status.

**Columns:**
- `id`, `fine_id`, `citizenid`, `charges`, `total_amount`
- `penalty_points`, `government_tax`, `pd_amount`, `issued_by`
- `issued_by_name`, `payment_coords`, `due_date`, `payment_date`
- `payment_location`, `payment_method`, `status`, `late_fee`
- `total_paid`, `payment_plan`, `installments`, `installment_amount`
- `next_payment_date`, `warrant_issued`, `warrant_date`, `notes`
- `created_at`, `updated_at`

### Evidence Tables

#### `zmdt_evidence`
Stores evidence information.

**Columns:**
- `id`, `evidence_id`, `case_id`, `incident_id`, `custody_id`
- `evidence_type`, `category`, `description`, `location_found`
- `coords_found`, `date_found`, `found_by`, `found_by_name`
- `collected_by`, `collected_by_name`, `collection_date`
- `storage_location`, `storage_box`, `storage_shelf`, `storage_locker`
- `chain_of_custody`, `photo_urls`, `video_urls`, `document_urls`
- `analysis_status`, `analysis_results`, `analyzed_by`, `analyzed_by_name`
- `analysis_date`, `dna_profile`, `fingerprint_data`, `drug_test_results`
- `ballistics_data`, `disposition`, `disposition_date`, `disposition_by`
- `disposition_by_name`, `disposition_reason`, `court_order`, `access_level`
- `min_rank_access`, `security_classification`, `retention_date`, `notes`
- `created_at`, `updated_at`

#### `zmdt_evidence_custody`
Stores chain of custody information.

**Columns:**
- `id`, `evidence_id`, `custody_id`, `action`, `performed_by`
- `performed_by_name`, `performed_by_rank`, `action_date`
- `location_from`, `location_to`, `condition`, `seal_number`
- `witness_1`, `witness_2`, `reason`, `notes`, `signature_hash`
- `created_at`

### Financial Tables

#### `zmdt_department_accounts`
Stores department financial accounts.

**Columns:**
- `id`, `account_id`, `department`, `account_type`, `balance`
- `total_received`, `total_spent`, `last_transaction`, `account_status`
- `created_at`, `updated_at`

#### `zmdt_transactions`
Stores financial transactions.

**Columns:**
- `id`, `transaction_id`, `account_id`, `transaction_type`, `amount`
- `balance_before`, `balance_after`, `reference_id`, `reference_type`
- `description`, `payer_id`, `payer_name`, `payee_id`, `payee_name`
- `payment_method`, `transaction_fee`, `tax_amount`, `government_share`
- `department_share`, `created_at`

## Permission System

### Job Permissions

Jobs can have the following MDT permissions:

- `view_people` - View citizen profiles
- `view_vehicles` - View vehicle information
- `create_incidents` - Create incident reports
- `issue_fines` - Issue fines and citations
- `create_warrants` - Create warrants
- `view_custody` - View custody records
- `manage_custody` - Manage custody (release, transfer)
- `view_audit_logs` - View audit logs
- `manage_evidence` - Manage evidence system
- `access_boss_menu` - Access boss menu
- `view_dispatch` - View dispatch calls
- `manage_dispatch` - Manage dispatch calls
- `view_reports` - View reports and statistics
- `create_reports` - Create reports
- `edit_reports` - Edit reports
- `delete_reports` - Delete reports
- `view_statistics` - View department statistics
- `manage_department` - Manage department settings
- `access_armory` - Access armory system
- `manage_fleet` - Manage vehicle fleet

### Evidence Permissions

Evidence system has specific permissions:

- `view_evidence` - View evidence entries
- `create_evidence` - Create new evidence
- `update_evidence` - Update existing evidence
- `analyze_evidence` - Submit evidence for analysis
- `transfer_evidence` - Transfer evidence between locations
- `dispose_evidence` - Dispose of evidence
- `manage_evidence` - Manage evidence system settings
- `admin_evidence` - Full administrative access
- `receive_notifications` - Receive evidence notifications

## Configuration API

### Theme Configuration

Themes can be customized in the config:

```lua
Config.UIThemes = {
    ['police'] = {
        primary_color = "#1a3c6e",
        secondary_color = "#2c5ba3",
        accent_color = "#4287f5",
        text_color = "#ffffff",
        background_color = "#0a1e37",
        success_color = "#28a745",
        warning_color = "#ffc107",
        error_color = "#dc3545",
        info_color = "#17a2b8"
    }
}
```

### Integration Configuration

External integrations can be configured:

```lua
Config.Integrations = {
    Police = 'wasabi_police',
    Ambulance = 'wasabi_ambulance',
    Banking = 'codm-banking',
    Dealership = 'jg-dealership',
    Discord = {
        enabled = true,
        bot_name = 'Z-MDT Bot'
    }
}
```

## Error Handling

### Error Codes

- `MDT001` - Database connection error
- `MDT002` - Insufficient permissions
- `MDT003` - Invalid input data
- `MDT004` - Evidence not found
- `MDT005` - Storage capacity exceeded
- `MDT006` - Analysis in progress
- `MDT007` - Invalid storage location
- `MDT008` - Chain of custody violation
- `MDT009` - Financial transaction failed
- `MDT010` - Webhook delivery failed

### Error Responses

All API endpoints return standardized error responses:

```json
{
    "success": false,
    "error": {
        "code": "MDT001",
        "message": "Database connection failed",
        "details": "Connection timeout after 30 seconds"
    }
}
```

## Rate Limiting

API endpoints are rate-limited to prevent abuse:

- Search endpoints: 100 requests per minute per player
- Create endpoints: 50 requests per minute per player
- Update endpoints: 200 requests per minute per player
- Delete endpoints: 20 requests per minute per player

## Security

### Authentication

All API requests require valid player authentication through QBCore.

### Authorization

Permission checks are performed on every API call based on:
- Player job and grade
- Specific permissions assigned
- Evidence access levels
- Security classifications

### Data Validation

All input data is validated before processing:
- SQL injection prevention
- XSS protection
- File upload validation
- Size limits enforcement

## Performance Optimization

### Caching

- Evidence cache: 5-minute TTL
- Player data cache: 3-minute TTL
- Vehicle data cache: 10-minute TTL
- Department statistics: 1-minute TTL

### Database Optimization

- Indexed columns for fast searches
- Query optimization with LIMIT clauses
- Batch operations for bulk updates
- Connection pooling with oxmysql

### Real-time Updates

- WebSocket-like updates through NUI messages
- Batched updates to reduce network traffic
- Compression for large data sets
- Delta updates for minimal data transfer

## Version History

### Version 2.0.0 (Current)
- Complete system overhaul
- Enhanced UI/UX
- Real-time updates
- Evidence system
- Government tax system
- Discord integration
- Performance optimizations

### Version 1.0.0
- Initial release
- Basic MDT functionality
- Incident management
- Fine system
- Warrant system

## Support

For API support and questions:
- GitHub Issues: Report bugs and request features
- Discord: Community support channel
- Documentation: Always refer to latest documentation

## Contributing

To contribute to the API:
1. Fork the repository
2. Create feature branch
3. Implement changes with documentation
4. Submit pull request
5. Include test cases

## License

This API documentation is provided under the same license as the Z-MDT Enhanced system.