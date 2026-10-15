-- 1. CalculateTotalCost
-- Returns the sum of all procedure costs for a given encounter.

DELIMITER $$
CREATE FUNCTION CalculateTotalCost(p_EncounterID INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Total DECIMAL(12,2);

    SELECT COALESCE(SUM(Cost), 0.00)
    INTO   v_Total
    FROM   Procedure_Table
    WHERE  EncounterID = p_EncounterID;

    RETURN v_Total;
END$$
DELIMITER ;

-- 2. CalculateInsuranceCoverage
-- Returns the dollar amount covered by insurance for a
-- given billing record, based on the policy coverage percent.

DELIMITER $$
CREATE FUNCTION CalculateInsuranceCoverage(p_BillingID INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_TotalCharges    DECIMAL(12,2);
    DECLARE v_CoveragePercent DECIMAL(5,2);
    DECLARE v_CoverageAmount  DECIMAL(12,2);

    SELECT b.TotalCharges, ip.CoveragePercent
    INTO   v_TotalCharges, v_CoveragePercent
    FROM   Billing b
    JOIN   InsurancePolicy ip ON b.PolicyID = ip.PolicyID
    WHERE  b.BillingID = p_BillingID;

    SET v_CoverageAmount = ROUND(v_TotalCharges * (v_CoveragePercent / 100), 2);

    RETURN COALESCE(v_CoverageAmount, 0.00);
END$$
DELIMITER ;
