-- STORED PROCEDURE 1:
-- Returns a complete encounter history for a given patient
-- in a single call, including encounter details, the treating 
-- provider, total procedure cost, and current billing status.

DELIMITER $$
CREATE PROCEDURE sp_GetPatientEncounterSummary(IN p_PatientID INT)
BEGIN
    SELECT
        e.EncounterID,
        e.EncounterType,
        e.EncounterStartTime,
        e.EncounterEndTime,
        e.Encounter_Status,
        e.Reason,
        CONCAT(s.FirstName, ' ', s.LastName) AS ProviderName,
        s.Specialty AS ProviderSpecialty,
        d.Dept_Name AS Department,
        COALESCE(SUM(pt.Cost), 0.00) AS TotalProcedureCost,
        b.Billing_Status,
        b.TotalCharges,
        b.AmountPaidToDate
    FROM Encounter e
    JOIN Staff s ON e.ProviderStaffID = s.StaffID
    JOIN Department d ON e.DepartmentID = d.DepartmentID
    LEFT JOIN Procedure_Table pt ON pt.EncounterID = e.EncounterID
    LEFT JOIN Billing b ON b.EncounterID = e.EncounterID
    WHERE e.PatientID = p_PatientID
    GROUP BY
        e.EncounterID, e.EncounterType, e.EncounterStartTime,
        e.EncounterEndTime, e.Encounter_Status, e.Reason,
        s.FirstName, s.LastName, s.Specialty,
        d.Dept_Name, b.Billing_Status,
        b.TotalCharges, b.AmountPaidToDate, e.PatientID
    ORDER BY e.EncounterStartTime DESC;
END$$
DELIMITER ;

-- STORED PROCEDURE 2:
-- Applies a payment to an existing billing record and
-- automatically resolves the correct Billing_Status based
-- on whether the patient's full responsibility has been met.

DELIMITER $$
CREATE PROCEDURE sp_ProcessBillingPayment(
    IN  p_BillingID INT,
    IN  p_PaymentAmount DECIMAL(12,2),
    OUT p_NewStatus VARCHAR(50)
)
BEGIN
    DECLARE v_Responsibility DECIMAL(12,2);
    DECLARE v_PaidToDate DECIMAL(12,2);
    DECLARE v_NewPaid DECIMAL(12,2);
    DECLARE v_NewStatus VARCHAR(50);

    -- grab current billing state
    SELECT PatientResponsibilityAmount, AmountPaidToDate
    INTO   v_Responsibility, v_PaidToDate
    FROM   Billing
    WHERE  BillingID = p_BillingID;
    SET v_NewPaid = v_PaidToDate + p_PaymentAmount;
    
    -- Cap payment at the responsibility amount (no overpayment allowed)
    IF v_NewPaid >= v_Responsibility THEN
        SET v_NewPaid = v_Responsibility;
        SET v_NewStatus = 'Paid';
    ELSE
        SET v_NewStatus = 'Partial';
    END IF;

    -- Apply the update
    UPDATE Billing
    SET    AmountPaidToDate = v_NewPaid,
           Billing_Status   = v_NewStatus,
           LastPaymentDate  = CURDATE()
    WHERE  BillingID = p_BillingID;

    -- Return the new status to the caller
    SET p_NewStatus = v_NewStatus;
END$$
DELIMITER ;
