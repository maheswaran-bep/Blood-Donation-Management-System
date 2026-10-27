-- ============================================================================
-- Blood Donation Management System (BDMS) - Fictional Seed Data
-- ============================================================================
USE `blood_donation_db`;

-- Disable foreign key checks momentarily for idempotent clean seeding
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Initial Users (Passwords are bcrypt hashed 'Admin@123' and 'Staff@123')
INSERT INTO `users` (`id`, `full_name`, `email`, `hashed_password`, `role`, `is_active`)
VALUES
  (1, 'Admin', 'admin@bloodbank.org', '$2b$12$WynhN.HmnBRo0i.037VgZuY/OkGHf31G9Pr/X46UT2T1Qh7gAZjny', 'admin', 1),
  (2, 'Aayush Dwivedi', 'aayush.dwivedi@bloodbank.org', '$2b$12$XC9Mg8bdIxq04j8LIuM4xeJRnyjnu3abznc9yfgeDaV84tSSlZv02', 'staff', 1),
  (3, 'Kairav Joshi', 'kairav.joshi@bloodbank.org', '$2b$12$XC9Mg8bdIxq04j8LIuM4xeJRnyjnu3abznc9yfgeDaV84tSSlZv02', 'staff', 1)
ON DUPLICATE KEY UPDATE `full_name` = VALUES(`full_name`), `email` = VALUES(`email`), `hashed_password` = VALUES(`hashed_password`);

-- 2. Registered Donors
INSERT INTO `donors` (`id`, `donor_code`, `full_name`, `email`, `phone`, `date_of_birth`, `gender`, `blood_group`, `address`, `city`, `is_eligible`, `last_donation_date`)
VALUES
  (1, 'DNR-1001', 'Aayush Dwivedi', 'aayush.dwivedi@example.com', '9876543210', '2006-11-09', 'Male', 'O+', '12 Civil Lines', 'Kanpur', 1, DATE_SUB(CURDATE(), INTERVAL 120 DAY)),
  (2, 'DNR-1002', 'Ananya Sharma', 'ananya.sharma@example.com', '9876543211', '1995-11-20', 'Female', 'A+', '24 Bhakrota', 'Jaipur', 1, DATE_SUB(CURDATE(), INTERVAL 95 DAY)),
  (3, 'DNR-1003', 'Arjun Mehta', 'arjun.mehta@example.com', '9876543212', '1988-03-30', 'Male', 'B-', '78 M.G. Road', 'Indore', 1, DATE_SUB(CURDATE(), INTERVAL 140 DAY)),
  (4, 'DNR-1004', 'Priya Sharma', 'priya.sharma@example.com', '9876543213', '1997-08-15', 'Female', 'AB+', '9 Malviya Nagar', 'Delhi', 1, DATE_SUB(CURDATE(), INTERVAL 30 DAY)),
  (5, 'DNR-1005', 'Rohan Verma', 'rohan.verma@example.com', '9876543214', '1990-12-05', 'Male', 'O-', '23 Gomti Nagar', 'Lucknow', 1, DATE_SUB(CURDATE(), INTERVAL 105 DAY)),
  (6, 'DNR-1006', 'Meera Iyer', 'meera.iyer@example.com', '9876543215', '1994-07-22', 'Female', 'A-', '67 Anna Nagar', 'Chennai', 1, DATE_SUB(CURDATE(), INTERVAL 180 DAY)),
  (7, 'DNR-1007', 'Kairav Joshi', 'kairav.joshi@example.com', '9876543216', '2007-03-25', 'Male', 'B+', '104 Vaishali Nagar', 'Jaipur', 1, DATE_SUB(CURDATE(), INTERVAL 110 DAY)),
  (8, 'DNR-1008', 'Kavya Nair', 'kavya.nair@example.com', '9876543217', '1999-09-09', 'Female', 'AB-', '33 Sodala', 'Jaipur', 1, NULL)
ON DUPLICATE KEY UPDATE `full_name` = VALUES(`full_name`), `email` = VALUES(`email`), `date_of_birth` = VALUES(`date_of_birth`), `blood_group` = VALUES(`blood_group`), `address` = VALUES(`address`), `city` = VALUES(`city`);

-- 3. Partner Hospitals
INSERT INTO `hospitals` (`id`, `hospital_code`, `name`, `license_number`, `contact_person`, `phone`, `email`, `address`, `city`)
VALUES
  (1, 'HSP-01', 'Saket Hospital', 'MED-LIC-88910', 'Dr. Rajiv Sharma', '011-2345678', 'contact@sakethospital.example', 'Saket, Jaipur', 'Jaipur'),
  (2, 'HSP-02', 'Manipal Hospital', 'MED-LIC-77402', 'Dr. Neha Kapoor', '011-8765432', 'bloodbank@manipalhospital.example', 'Sector 62, Institutional Area', 'Kanpur'),
  (3, 'HSP-03', 'Base Hospital Delhi Cantt', 'MED-LIC-66291', 'Dr. Anil Verma', '011-3456789', 'contact@basehospital.example', 'Delhi Cantonment', 'Delhi'),
  (4, 'HSP-04', 'Dulet Trauma Center', 'MED-LIC-55182', 'Dr. Meenal Joshi', '011-9012345', 'contact@dulettrauma.example', 'Ring Road, Civil Lines', 'Jaipur')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `contact_person` = VALUES(`contact_person`), `email` = VALUES(`email`), `address` = VALUES(`address`), `city` = VALUES(`city`);

-- 4. Donation Events
INSERT INTO `donation_events` (`id`, `event_code`, `title`, `organizer`, `venue`, `city`, `event_date`, `start_time`, `end_time`, `capacity`, `status`, `description`)
VALUES
  (1, 'EVT-2026-01', 'Manipal Rotaract Blood Donation Drive', 'Manipal Rotaract Club', 'Manipal University Campus', 'Jaipur', DATE_ADD(CURDATE(), INTERVAL 14 DAY), '09:00:00', '16:00:00', 120, 'Upcoming', 'Student-led blood donation camp organized with the Manipal Rotaract Club.'),
  (2, 'EVT-2026-02', 'Base Hospital Blood Donor Day Drive', 'Base Hospital Delhi Cantt', 'Base Hospital Auditorium', 'Delhi', DATE_ADD(CURDATE(), INTERVAL 28 DAY), '10:00:00', '17:00:00', 200, 'Upcoming', 'Blood Donor Day camp organized by Base Hospital Delhi Cantt.'),
  (3, 'EVT-2026-03', 'Saket Hospital Community Blood Donation Drive', 'Saket Hospital Volunteer Group', 'Saket Hospital Hall', 'Jaipur', DATE_SUB(CURDATE(), INTERVAL 7 DAY), '09:30:00', '15:30:00', 80, 'Completed', 'Community blood donation camp hosted by Saket Hospital volunteers.')
ON DUPLICATE KEY UPDATE `title` = VALUES(`title`), `organizer` = VALUES(`organizer`), `venue` = VALUES(`venue`), `city` = VALUES(`city`), `description` = VALUES(`description`);

-- 5. Event Registrations
INSERT INTO `event_registrations` (`id`, `event_id`, `donor_id`, `status`)
VALUES
  (1, 1, 1, 'Registered'),
  (2, 1, 2, 'Registered'),
  (3, 1, 5, 'Registered'),
  (4, 2, 3, 'Registered'),
  (5, 3, 6, 'Attended')
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);

-- 6. Donations
INSERT INTO `donations` (`id`, `donation_code`, `donor_id`, `event_id`, `donation_date`, `blood_group`, `component_type`, `units`, `hemoglobin_g_dl`, `blood_pressure`, `pulse_rate`, `screening_status`, `status`, `inventory_generated`, `remarks`, `recorded_by`)
VALUES
  (1, 'DON-2026-001', 1, 3, DATE_SUB(CURDATE(), INTERVAL 20 DAY), 'O+', 'Whole Blood', 1, 14.5, '120/80', 72, 'Passed', 'Completed', 1, 'Routine voluntary donation; donor well hydrated.', 1),
  (2, 'DON-2026-002', 2, 3, DATE_SUB(CURDATE(), INTERVAL 18 DAY), 'A+', 'Whole Blood', 1, 13.8, '118/76', 70, 'Passed', 'Completed', 1, 'Standard donation without adverse reactions.', 2),
  (3, 'DON-2026-003', 3, NULL, DATE_SUB(CURDATE(), INTERVAL 15 DAY), 'B-', 'Whole Blood', 1, 15.1, '124/82', 74, 'Passed', 'Completed', 1, 'Walk-in donation at main blood center.', 1),
  (4, 'DON-2026-004', 5, NULL, DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'O-', 'Whole Blood', 1, 14.2, '122/80', 68, 'Passed', 'Completed', 1, 'Universal donor emergency reserve unit.', 2),
  (5, 'DON-2026-005', 6, NULL, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 'A-', 'Whole Blood', 1, 13.5, '116/74', 72, 'Passed', 'Completed', 1, 'Clean draw, stored in refrigerator shelf B.', 1),
  (6, 'DON-2026-006', 7, NULL, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'B+', 'Whole Blood', 1, 14.9, '125/80', 76, 'Passed', 'Completed', 1, 'Scheduled center appointment.', 2),
  (7, 'DON-2026-007', 4, NULL, CURDATE(), 'AB+', 'Platelets', 1, 13.1, '115/75', 70, 'Passed', 'Scheduled', 0, 'Pre-donation check scheduled for afternoon session.', 1)
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);

-- 7. Blood Inventory Batches
INSERT INTO `blood_inventory` (`id`, `batch_number`, `donation_id`, `blood_group`, `component_type`, `volume_ml`, `collection_date`, `expiry_date`, `status`, `storage_location`)
VALUES
  (1, 'BATCH-O-POS-001', 1, 'O+', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 20 DAY), INTERVAL 42 DAY), 'Available', 'Main Cold Room - Shelf A1'),
  (2, 'BATCH-A-POS-001', 2, 'A+', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 18 DAY), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 18 DAY), INTERVAL 42 DAY), 'Available', 'Main Cold Room - Shelf A2'),
  (3, 'BATCH-B-NEG-001', 3, 'B-', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 15 DAY), INTERVAL 42 DAY), 'Available', 'Main Cold Room - Shelf B1'),
  (4, 'BATCH-O-NEG-001', 4, 'O-', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 10 DAY), INTERVAL 42 DAY), 'Available', 'Critical Storage Safe Box 1'),
  (5, 'BATCH-A-NEG-001', 5, 'A-', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 5 DAY), INTERVAL 42 DAY), 'Available', 'Main Cold Room - Shelf B2'),
  (6, 'BATCH-B-POS-001', 6, 'B+', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 2 DAY), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 2 DAY), INTERVAL 42 DAY), 'Available', 'Main Cold Room - Shelf A3'),
  (7, 'BATCH-AB-POS-001', NULL, 'AB+', 'Platelets', 300, DATE_SUB(CURDATE(), INTERVAL 1 DAY), DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'Available', 'Agitator Unit 1'),
  (8, 'BATCH-AB-NEG-001', NULL, 'AB-', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 39 DAY), DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'Available', 'Main Cold Room - Shelf C1'),
  (9, 'BATCH-OLD-EXP-01', NULL, 'O+', 'Whole Blood', 450, DATE_SUB(CURDATE(), INTERVAL 50 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'Expired', 'Quarantine Shelf Q1')
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);

-- 8. Hospital Blood Requests
INSERT INTO `blood_requests` (`id`, `request_code`, `hospital_id`, `patient_name`, `blood_group`, `component_type`, `units_requested`, `units_fulfilled`, `urgency`, `required_date`, `status`, `notes`)
VALUES
  (1, 'REQ-2026-101', 1, 'Aarav Singh', 'O+', 'Whole Blood', 2, 1, 'Critical', CURDATE(), 'Partially Fulfilled', 'Cardiac surgical backup required immediately.'),
  (2, 'REQ-2026-102', 2, 'Ishita Gupta', 'A+', 'Whole Blood', 1, 1, 'Normal', DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'Fulfilled', 'Orthopedic knee reconstruction operation.'),
  (3, 'REQ-2026-103', 3, 'Vihaan Mishra', 'O-', 'Whole Blood', 1, 0, 'Critical', DATE_ADD(CURDATE(), INTERVAL 1 DAY), 'Approved', 'Pediatric ICU neonatal urgent exchange.'),
  (4, 'REQ-2026-104', 4, 'Ananya Rao', 'B+', 'Whole Blood', 3, 0, 'Urgent', DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'Pending', 'Scheduled oncological surgery preparation.')
ON DUPLICATE KEY UPDATE `patient_name` = VALUES(`patient_name`), `status` = VALUES(`status`);

-- 9. Blood Issues & Audit Items
INSERT INTO `blood_issues` (`id`, `issue_code`, `request_id`, `units_issued`, `issued_date`, `issued_by`, `recipient_name`, `notes`)
VALUES
  (1, 'ISS-2026-001', 2, 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 1, 'Nurse Priya Sharma', 'Delivered via temperature controlled cold transporter.'),
  (2, 'ISS-2026-002', 1, 1, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 2, 'EMT Rahul Verma', 'First unit delivered for emergency bypass prep.')
ON DUPLICATE KEY UPDATE `recipient_name` = VALUES(`recipient_name`);

SET FOREIGN_KEY_CHECKS = 1;
