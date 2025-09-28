CREATE TABLE IF NOT EXISTS `zmdt_citizens` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `firstname` varchar(50) NOT NULL,
    `lastname` varchar(50) NOT NULL,
    `dob` date NOT NULL,
    `phone` varchar(20) DEFAULT NULL,
    `address` text DEFAULT NULL,
    `mugshot` text DEFAULT NULL,
    `notes` text DEFAULT NULL,
    `penalty_points` int(11) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`)
);

CREATE TABLE IF NOT EXISTS `zmdt_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `plate` varchar(10) NOT NULL,
    `model` varchar(50) NOT NULL,
    `owner` varchar(50) NOT NULL,
    `color` varchar(50) DEFAULT NULL,
    `stolen` tinyint(1) DEFAULT 0,
    `impounded` tinyint(1) DEFAULT 0,
    `notes` text DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`)
);

CREATE TABLE IF NOT EXISTS `zmdt_incidents` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `incident_id` varchar(20) NOT NULL,
    `title` varchar(255) NOT NULL,
    `description` text NOT NULL,
    `location` varchar(255) NOT NULL,
    `coords` text DEFAULT NULL,
    `officer_id` varchar(50) NOT NULL,
    `officer_name` varchar(100) NOT NULL,
    `status` enum('active','closed','pending') DEFAULT 'active',
    `priority` enum('low','medium','high','critical') DEFAULT 'medium',
    `type` enum('police','medical','fire') DEFAULT 'police',
    `involved_citizens` text DEFAULT NULL,
    `involved_vehicles` text DEFAULT NULL,
    `evidence` text DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `incident_id` (`incident_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_warrants` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `warrant_id` varchar(20) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `charges` text NOT NULL,
    `description` text NOT NULL,
    `issued_by` varchar(50) NOT NULL,
    `issued_by_name` varchar(100) NOT NULL,
    `status` enum('active','executed','cancelled') DEFAULT 'active',
    `bail_amount` int(11) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `warrant_id` (`warrant_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_fines` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `fine_id` varchar(20) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `charges` text NOT NULL,
    `total_amount` int(11) NOT NULL,
    `penalty_points` int(11) DEFAULT 0,
    `issued_by` varchar(50) NOT NULL,
    `issued_by_name` varchar(100) NOT NULL,
    `status` enum('unpaid','paid','overdue') DEFAULT 'unpaid',
    `payment_coords` text DEFAULT NULL,
    `due_date` timestamp NULL DEFAULT NULL,
    `paid_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fine_id` (`fine_id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_custody` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `charges` text NOT NULL,
    `arresting_officer` varchar(50) NOT NULL,
    `officer_name` varchar(100) NOT NULL,
    `custody_time` int(11) NOT NULL,
    `bail_amount` int(11) DEFAULT 0,
    `status` enum('in_custody','released','bailed') DEFAULT 'in_custody',
    `cell_number` int(11) DEFAULT NULL,
    `notes` text DEFAULT NULL,
    `arrested_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `released_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_audit_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `action` varchar(100) NOT NULL,
    `user_id` varchar(50) NOT NULL,
    `user_name` varchar(100) NOT NULL,
    `details` text DEFAULT NULL,
    `ip_address` varchar(45) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `zmdt_dispatch_calls` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `call_id` varchar(20) NOT NULL,
    `title` varchar(255) NOT NULL,
    `description` text NOT NULL,
    `location` varchar(255) NOT NULL,
    `coords` text NOT NULL,
    `caller` varchar(100) DEFAULT 'Anonymous',
    `priority` enum('low','medium','high','critical') DEFAULT 'medium',
    `type` enum('police','medical','fire') DEFAULT 'police',
    `status` enum('pending','assigned','en_route','on_scene','closed') DEFAULT 'pending',
    `assigned_units` text DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `call_id` (`call_id`)
);
