-- MDT SQL Schema for QBCore Compatibility
-- All tables use QBCore foreign keys and avoid duplicating base fields
-- All default/sample data uses INSERT IGNORE
-- No unsupported SQL features

CREATE TABLE IF NOT EXISTS `zmdt_citizens` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL, -- QBCore foreign key
    `notes` TEXT DEFAULT NULL,
    `penalty_points` INT(11) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`)
);

CREATE TABLE IF NOT EXISTS `zmdt_vehicles` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(12) NOT NULL, -- QBCore foreign key
    `notes` TEXT DEFAULT NULL,
    `stolen` TINYINT(1) DEFAULT 0,
    `impounded` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`)
);

CREATE TABLE IF NOT EXISTS `zmdt_incidents` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `incident_id` VARCHAR(50) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `location` VARCHAR(255) NOT NULL,
    `officer_id` VARCHAR(50) NOT NULL, -- QBCore citizenid
    `officer_name` VARCHAR(100) NOT NULL,
    `status` ENUM('active','closed','pending') DEFAULT 'active',
    `priority` ENUM('low','medium','high','critical') DEFAULT 'medium',
    `type` ENUM('police','medical','fire') DEFAULT 'police',
    `involved_citizens` TEXT DEFAULT NULL,
    `involved_vehicles` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `incident_id` (`incident_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_warrants` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `warrant_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL, -- QBCore foreign key
    `charges` TEXT NOT NULL,
    `description` TEXT NOT NULL,
    `issued_by` VARCHAR(50) NOT NULL, -- QBCore citizenid
    `issued_by_name` VARCHAR(100) NOT NULL,
    `status` ENUM('active','executed','cancelled') DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `warrant_id` (`warrant_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_fines` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `fine_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL, -- QBCore foreign key
    `charges` TEXT NOT NULL,
    `total_amount` INT(11) NOT NULL,
    `issued_by` VARCHAR(50) NOT NULL, -- QBCore citizenid
    `issued_by_name` VARCHAR(100) NOT NULL,
    `status` ENUM('unpaid','paid','overdue') DEFAULT 'unpaid',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fine_id` (`fine_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_custody` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL, -- QBCore foreign key
    `charges` TEXT NOT NULL,
    `arresting_officer` VARCHAR(50) NOT NULL, -- QBCore citizenid
    `officer_name` VARCHAR(100) NOT NULL,
    `custody_time` INT(11) NOT NULL,
    `status` ENUM('in_custody','released','bailed') DEFAULT 'in_custody',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_audit_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `action` VARCHAR(100) NOT NULL,
    `user_id` VARCHAR(50) NOT NULL, -- QBCore citizenid
    `user_name` VARCHAR(100) NOT NULL,
    `details` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_dispatch_calls` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `call_id` VARCHAR(50) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `location` VARCHAR(255) NOT NULL,
    `caller` VARCHAR(100) DEFAULT 'Anonymous',
    `priority` ENUM('low','medium','high','critical') DEFAULT 'medium',
    `type` ENUM('police','medical','fire') DEFAULT 'police',
    `status` ENUM('pending','assigned','en_route','on_scene','closed') DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `call_id` (`call_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_medical_records` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `record_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL, -- QBCore foreign key
    `doctor_id` VARCHAR(50) NOT NULL, -- QBCore citizenid
    `doctor_name` VARCHAR(100) NOT NULL,
    `diagnosis` TEXT NOT NULL,
    `treatment` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `record_id` (`record_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_department_accounts` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `department` VARCHAR(50) NOT NULL,
    `balance` INT(11) DEFAULT 0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `department` (`department`)
);

CREATE TABLE IF NOT EXISTS `zmdt_department_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `department` VARCHAR(50) NOT NULL,
    `amount` INT(11) NOT NULL,
    `type` ENUM('deposit','withdrawal') NOT NULL,
    `description` TEXT NOT NULL,
    `created_by` VARCHAR(50) NOT NULL, -- QBCore citizenid
    `created_by_name` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

-- Insert default department accounts
INSERT IGNORE INTO `zmdt_department_accounts` (`department`, `balance`) VALUES
('police', 0),
('sheriff', 0),
('ambulance', 0);

-- Insert sample job ranks (safe to use IGNORE)
INSERT IGNORE INTO zmdt_job_ranks (job_name, grade_level, grade_name, label, permissions, mdt_permissions) VALUES
('police', 0, 'recruit', 'Police Recruit', '["view_people"]', '["view_people", "view_vehicles"]'),
('police', 1, 'officer', 'Police Officer', '["view_people", "create_incidents"]', '["view_people", "view_vehicles", "create_incidents", "issue_fines"]'),
('police', 2, 'sergeant', 'Sergeant', '["view_people", "create_incidents", "manage_officers"]', '["view_people", "view_vehicles", "create_incidents", "issue_fines", "create_warrants", "view_custody"]'),
('police', 3, 'lieutenant', 'Lieutenant', '["view_people", "create_incidents", "manage_officers", "boss_actions"]', '["view_people", "view_vehicles", "create_incidents", "issue_fines", "create_warrants", "view_custody", "manage_custody"]'),
('police', 4, 'captain', 'Captain', '["view_people", "create_incidents", "manage_officers", "boss_actions"]', '["view_people", "view_vehicles", "create_incidents", "issue_fines", "create_warrants", "view_custody", "manage_custody", "view_audit_logs"]'),
('police', 5, 'chief', 'Chief of Police', '["view_people", "create_incidents", "manage_officers", "boss_actions"]', '["view_people", "view_vehicles", "create_incidents", "issue_fines", "create_warrants", "view_custody", "manage_custody", "view_audit_logs", "manage_department"]');

-- Clean up old audit logs (run manually or via a scheduled task)
DELETE FROM `zmdt_audit_logs` WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 30 DAY);