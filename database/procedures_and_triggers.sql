-- ============================================================================
-- Blood Donation Management System (BDMS) - Stored Procedures & Triggers
-- Database: blood_donation_db
-- Compatible with MySQL 8.0+
-- ============================================================================

USE `blood_donation_db`;

-- ============================================================================
-- PART 1: TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Trigger 1: trg_after_donation_completed
-- Description: Automatically updates the donor's `last_donation_date` in the 
-- `donors` table whenever a donation record is inserted with status 'Completed'.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_after_donation_completed`;
DELIMITER $$
CREATE TRIGGER `trg_after_donation_completed`
AFTER INSERT ON `donations`
FOR EACH ROW
BEGIN
    IF NEW.status = 'Completed' THEN
        UPDATE `donors`
        SET `last_donation_date` = NEW.donation_date
        WHERE `id` = NEW.donor_id;
    END IF;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- Trigger 2: trg_update_donation_completed
-- Description: Automatically updates the donor's `last_donation_date` when an 
-- existing scheduled donation is transitioned to 'Completed'.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_update_donation_completed`;
DELIMITER $$
CREATE TRIGGER `trg_update_donation_completed`
AFTER UPDATE ON `donations`
FOR EACH ROW
BEGIN
    IF NEW.status = 'Completed' AND OLD.status <> 'Completed' THEN
        UPDATE `donors`
        SET `last_donation_date` = NEW.donation_date
        WHERE `id` = NEW.donor_id;
    END IF;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- Trigger 3: trg_prevent_over_capacity_registration
-- Description: Enforces venue capacity constraints before inserting a donor 
-- pre-registration for a community donation drive. Raises SQLSTATE '45000'.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_prevent_over_capacity_registration`;
DELIMITER $$
CREATE TRIGGER `trg_prevent_over_capacity_registration`
BEFORE INSERT ON `event_registrations`
FOR EACH ROW
BEGIN
    DECLARE v_capacity INT;
    DECLARE v_current_count INT;

    -- Fetch maximum event capacity
    SELECT `capacity` INTO v_capacity
    FROM `donation_events`
    WHERE `id` = NEW.event_id;

    -- Count active registrations
    SELECT COUNT(*) INTO v_current_count
    FROM `event_registrations`
    WHERE `event_id` = NEW.event_id AND `status` <> 'Cancelled';

    IF v_current_count >= v_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Event registration failed: Event venue has reached maximum capacity.';
    END IF;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- Trigger 4: trg_check_inventory_expiry_before_update
-- Description: Automatically flags an inventory batch as 'Expired' if today's 
-- date surpasses the batch's `expiry_date`.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_check_inventory_expiry_before_update`;
DELIMITER $$
CREATE TRIGGER `trg_check_inventory_expiry_before_update`
BEFORE UPDATE ON `blood_inventory`
FOR EACH ROW
BEGIN
    IF NEW.expiry_date < CURDATE() AND NEW.status = 'Available' THEN
        SET NEW.status = 'Expired';
    END IF;
END$$
DELIMITER ;


-- ============================================================================
-- PART 2: STORED PROCEDURES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Procedure 1: sp_check_donor_eligibility
-- Description: Determines whether a donor is medically eligible to donate blood
-- based on the mandatory 90-day minimum gap interval between donations.
-- Parameters:
--   IN  p_donor_id       : ID of the donor to evaluate
--   OUT p_is_eligible    : 1 if eligible, 0 if deferred
--   OUT p_days_remaining : Number of days remaining before next eligible donation
--   OUT p_message        : Human-readable status message
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `sp_check_donor_eligibility`;
DELIMITER $$
CREATE PROCEDURE `sp_check_donor_eligibility`(
    IN  p_donor_id       INT,
    OUT p_is_eligible    BOOLEAN,
    OUT p_days_remaining INT,
    OUT p_message        VARCHAR(255)
)
BEGIN
    DECLARE v_last_donation DATE;
    DECLARE v_days_since INT;
    DECLARE v_min_gap INT DEFAULT 90;
    DECLARE v_donor_name VARCHAR(120);

    -- Fetch donor information
    SELECT `full_name`, `last_donation_date`
    INTO v_donor_name, v_last_donation
    FROM `donors`
    WHERE `id` = p_donor_id;

    IF v_donor_name IS NULL THEN
        SET p_is_eligible = FALSE;
        SET p_days_remaining = 0;
        SET p_message = 'Donor record not found.';
    ELSEIF v_last_donation IS NULL THEN
        SET p_is_eligible = TRUE;
        SET p_days_remaining = 0;
        SET p_message = CONCAT(v_donor_name, ' has never donated and is eligible.');
    ELSE
        SET v_days_since = DATEDIFF(CURDATE(), v_last_donation);
        IF v_days_since >= v_min_gap THEN
            SET p_is_eligible = TRUE;
            SET p_days_remaining = 0;
            SET p_message = CONCAT(v_donor_name, ' is eligible to donate. Last donation was ', v_days_since, ' days ago.');
        ELSE
            SET p_is_eligible = FALSE;
            SET p_days_remaining = v_min_gap - v_days_since;
            SET p_message = CONCAT(v_donor_name, ' is deferred. Must wait ', p_days_remaining, ' more day(s).');
        END IF;
    END IF;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- Procedure 2: sp_get_blood_stock_summary
-- Description: Produces an aggregated real-time stock report grouped by blood group
-- comparing available units against the configured low-stock threshold.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `sp_get_blood_stock_summary`;
DELIMITER $$
CREATE PROCEDURE `sp_get_blood_stock_summary`()
BEGIN
    DECLARE v_threshold INT DEFAULT 5;

    -- Lookup threshold from system_settings if present
    SELECT CAST(`setting_value` AS UNSIGNED) INTO v_threshold
    FROM `system_settings`
    WHERE `setting_key` = 'low_stock_threshold'
    LIMIT 1;

    SELECT 
        bg.blood_group,
        COALESCE(COUNT(bi.id), 0) AS available_units,
        v_threshold AS low_stock_threshold,
        CASE 
            WHEN COALESCE(COUNT(bi.id), 0) = 0 THEN 'CRITICAL (OUT OF STOCK)'
            WHEN COALESCE(COUNT(bi.id), 0) < v_threshold THEN 'WARNING (LOW STOCK)'
            ELSE 'HEALTHY'
        END AS stock_status,
        MIN(bi.expiry_date) AS earliest_expiry_date
    FROM (
        SELECT 'A+' AS blood_group UNION ALL
        SELECT 'A-' UNION ALL
        SELECT 'B+' UNION ALL
        SELECT 'B-' UNION ALL
        SELECT 'AB+' UNION ALL
        SELECT 'AB-' UNION ALL
        SELECT 'O+' UNION ALL
        SELECT 'O-'
    ) bg
    LEFT JOIN `blood_inventory` bi 
        ON bg.blood_group = bi.blood_group 
        AND bi.status = 'Available' 
        AND bi.expiry_date >= CURDATE()
    GROUP BY bg.blood_group
    ORDER BY available_units ASC;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- Procedure 3: sp_issue_blood_fifo
-- Description: Executes ACID transactional blood issuing for hospital requests.
-- Allocates batches based on FIFO (Earliest Expiry First) to eliminate wastage,
-- inserts an audit record into `blood_issues`, links individual batches in
-- `blood_issue_items`, updates inventory batch statuses to 'Issued', and 
-- recalculates request fulfillment status atomically.
-- Parameters:
--   IN  p_request_id       : ID of the approved hospital blood request
--   IN  p_units_to_issue   : Number of units to allocate
--   IN  p_issued_by        : User ID of authorizing staff/admin
--   IN  p_recipient_name   : Name of authorized receiving hospital staff
--   OUT p_status_code      : Return code (0 = Success, 1 = Error)
--   OUT p_status_message   : Return status message
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `sp_issue_blood_fifo`;
DELIMITER $$
CREATE PROCEDURE `sp_issue_blood_fifo`(
    IN  p_request_id       INT,
    IN  p_units_to_issue   INT,
    IN  p_issued_by        INT,
    IN  p_recipient_name   VARCHAR(100),
    OUT p_status_code      INT,
    OUT p_status_message   VARCHAR(255)
)
proc_block: BEGIN
    DECLARE v_blood_group VARCHAR(10);
    DECLARE v_component_type VARCHAR(30);
    DECLARE v_units_requested INT;
    DECLARE v_units_fulfilled INT;
    DECLARE v_req_status VARCHAR(30);
    DECLARE v_available_count INT;
    DECLARE v_issue_id INT;
    DECLARE v_issue_code VARCHAR(25);
    DECLARE v_remaining INT;

    -- Error handler: Rollback transaction on SQL exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = 1;
        SET p_status_message = 'Database Exception: Transaction rolled back.';
    END;

    -- Parameter validations
    IF p_units_to_issue <= 0 THEN
        SET p_status_code = 1;
        SET p_status_message = 'Invalid unit count: Units to issue must be greater than 0.';
        LEAVE proc_block;
    END IF;

    START TRANSACTION;

    -- 1. Fetch & lock blood request
    SELECT 
        `blood_group`, `component_type`, `units_requested`, `units_fulfilled`, `status`
    INTO 
        v_blood_group, v_component_type, v_units_requested, v_units_fulfilled, v_req_status
    FROM `blood_requests`
    WHERE `id` = p_request_id
    FOR UPDATE;

    IF v_req_status IS NULL THEN
        ROLLBACK;
        SET p_status_code = 1;
        SET p_status_message = 'Blood request record not found.';
        LEAVE proc_block;
    END IF;

    IF v_req_status NOT IN ('Pending', 'Approved', 'Partially Fulfilled') THEN
        ROLLBACK;
        SET p_status_code = 1;
        SET p_status_message = CONCAT('Cannot issue blood: Request status is already ', v_req_status);
        LEAVE proc_block;
    END IF;

    SET v_remaining = v_units_requested - v_units_fulfilled;
    IF p_units_to_issue > v_remaining THEN
        ROLLBACK;
        SET p_status_code = 1;
        SET p_status_message = CONCAT('Units to issue (', p_units_to_issue, ') exceeds remaining balance (', v_remaining, ').');
        LEAVE proc_block;
    END IF;

    -- 2. Verify sufficient unexpired available stock
    SELECT COUNT(*) INTO v_available_count
    FROM `blood_inventory`
    WHERE `blood_group` = v_blood_group 
      AND `component_type` = v_component_type 
      AND `status` = 'Available' 
      AND `expiry_date` >= CURDATE();

    IF v_available_count < p_units_to_issue THEN
        ROLLBACK;
        SET p_status_code = 1;
        SET p_status_message = CONCAT('Insufficient stock for ', v_blood_group, ' ', v_component_type, '. Available: ', v_available_count, ', Required: ', p_units_to_issue);
        LEAVE proc_block;
    END IF;

    -- 3. Create blood issue audit record
    SET v_issue_code = CONCAT('ISS-', UPPER(HEX(RANDOM_BYTES(4))));
    INSERT INTO `blood_issues` (`issue_code`, `request_id`, `units_issued`, `issued_by`, `recipient_name`, `notes`)
    VALUES (v_issue_code, p_request_id, p_units_to_issue, p_issued_by, p_recipient_name, 'Issued via stored procedure sp_issue_blood_fifo');

    SET v_issue_id = LAST_INSERT_ID();

    -- 4. Temporary table to capture exact batches allocated via FIFO
    DROP TEMPORARY TABLE IF EXISTS `temp_allocated_batches`;
    CREATE TEMPORARY TABLE `temp_allocated_batches` (
        `inv_id` INT PRIMARY KEY
    );

    INSERT INTO `temp_allocated_batches` (`inv_id`)
    SELECT `id`
    FROM `blood_inventory`
    WHERE `blood_group` = v_blood_group 
      AND `component_type` = v_component_type 
      AND `status` = 'Available' 
      AND `expiry_date` >= CURDATE()
    ORDER BY `expiry_date` ASC
    LIMIT p_units_to_issue;

    -- 5. Insert batch audit items
    INSERT INTO `blood_issue_items` (`issue_id`, `inventory_id`)
    SELECT v_issue_id, `inv_id` FROM `temp_allocated_batches`;

    -- 6. Update inventory batches to 'Issued'
    UPDATE `blood_inventory`
    SET `status` = 'Issued'
    WHERE `id` IN (SELECT `inv_id` FROM `temp_allocated_batches`);

    DROP TEMPORARY TABLE IF EXISTS `temp_allocated_batches`;

    -- 7. Update request progress
    UPDATE `blood_requests`
    SET 
        `units_fulfilled` = `units_fulfilled` + p_units_to_issue,
        `status` = CASE 
            WHEN `units_fulfilled` + p_units_to_issue >= `units_requested` THEN 'Fulfilled' 
            ELSE 'Partially Fulfilled' 
        END
    WHERE `id` = p_request_id;

    COMMIT;
    SET p_status_code = 0;
    SET p_status_message = CONCAT('Success: Allocated and issued ', p_units_to_issue, ' unit(s) under code ', v_issue_code);
END$$
DELIMITER ;
