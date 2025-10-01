-- Z-MDT Database Setup
-- Run these SQL commands to set up the required tables

-- Create fines table
CREATE TABLE IF NOT EXISTS `zmdt_fines` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `fine_id` varchar(50) NOT NULL UNIQUE,
    `citizenid` varchar(50) NOT NULL,
    `charges` longtext,
    `total_amount` int(11) NOT NULL DEFAULT 0,
    `penalty_points` int(11) NOT NULL DEFAULT 0,
    `issued_by` varchar(50) NOT NULL,
    `issued_by_name` varchar(100) NOT NULL,
    `status` enum('unpaid','paid','cancelled') DEFAULT 'unpaid',
    `payment_coords` longtext,
    `due_date` datetime NOT NULL,
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    `paid_at` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create incidents table
CREATE TABLE IF NOT EXISTS `zmdt_incidents` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `incident_id` varchar(50) NOT NULL UNIQUE,
    `title` varchar(255) NOT NULL,
    `description` longtext,
    `location` varchar(255),
    `officers` longtext,
    `citizens` longtext,
    `evidence` longtext,
    `status` enum('open','closed','pending') DEFAULT 'open',
    `priority` enum('low','medium','high','urgent') DEFAULT 'medium',
    `created_by` varchar(50) NOT NULL,
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `status` (`status`),
    KEY `priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create BOLOs table
CREATE TABLE IF NOT EXISTS `zmdt_bolos` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `bolo_id` varchar(50) NOT NULL UNIQUE,
    `type` enum('person','vehicle') NOT NULL,
    `description` longtext NOT NULL,
    `details` longtext,
    `created_by` varchar(50) NOT NULL,
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    `expires_at` datetime,
    `is_active` tinyint(1) DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `type` (`type`),
    KEY `is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create custody records table
CREATE TABLE IF NOT EXISTS `zmdt_custody` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `record_id` varchar(50) NOT NULL UNIQUE,
    `citizenid` varchar(50) NOT NULL,
    `charges` longtext,
    `sentence_days` int(11) NOT NULL,
    `cell_number` int(11),
    `jail_location` varchar(255),
    `arresting_officer` varchar(50) NOT NULL,
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    `release_date` datetime,
    `status` enum('active','released','escaped') DEFAULT 'active',
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create citizens table (for extended info)
CREATE TABLE IF NOT EXISTS `zmdt_citizens` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL UNIQUE,
    `firstname` varchar(50) NOT NULL,
    `lastname` varchar(50) NOT NULL,
    `dob` date,
    `phone` varchar(20),
    `license` varchar(50),
    `penalty_points` int(11) DEFAULT 0,
    `notes` longtext,
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create activity log table
CREATE TABLE IF NOT EXISTS `zmdt_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50),
    `action` varchar(50) NOT NULL,
    `details` longtext,
    `timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `action` (`action`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert sample data for testing
INSERT INTO `zmdt_citizens` (`citizenid`, `firstname`, `lastname`, `dob`, `phone`, `license`) VALUES
('TEST001', 'John', 'Doe', '1990-01-15', '555-1234', 'D12345678'),
('TEST002', 'Jane', 'Smith', '1985-03-22', '555-5678', 'D87654321')
ON DUPLICATE KEY UPDATE 
    firstname = VALUES(firstname),
    lastname = VALUES(lastname);

-- Grant permissions (adjust for your database user)
GRANT SELECT, INSERT, UPDATE, DELETE ON your_database.zmdt_* TO 'your_user'@'localhost';
FLUSH PRIVILEGES;