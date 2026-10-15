-- TRIGGER 1:
-- Automatically writes an entry to AuditLog whenever a new Billing record is inserted.

DELIMITER $$
CREATE TRIGGER trg_AfterBillingInsert_AuditLog
AFTER INSERT ON Billing
FOR EACH ROW
BEGIN
    DECLARE v_StaffID INT;
    SELECT ProviderStaffID
    INTO   v_StaffID
    FROM   Encounter
    WHERE  EncounterID = NEW.EncounterID
    LIMIT  1;
    INSERT INTO AuditLog (StaffID, Audit_Action, EntityName, EntityID, IPAddress)
    VALUES (
        COALESCE(v_StaffID, 1),
        'INSERT',
        'Billing',
        NEW.BillingID,
        '127.0.0.1' -- system-generated entry (loopback address for locolhost) (implies system generated)
    );
END$$
DELIMITER ;

-- TRIGGER 2:
--   Automatically updates the Room status to Available
--   whenever an Encounter transitions to Discharged or Completed.

DELIMITER $$
CREATE TRIGGER trg_AfterEncounterUpdate_RoomStatus
AFTER UPDATE ON Encounter
FOR EACH ROW
BEGIN
    IF NEW.Encounter_Status IN ('Discharged', 'Completed')
       AND OLD.Encounter_Status NOT IN ('Discharged', 'Completed')
       AND NEW.RoomID IS NOT NULL
    THEN
        UPDATE Room
        SET    Room_Status = 'Available'
        WHERE  RoomID = NEW.RoomID;
    END IF;
END$$
DELIMITER ;
