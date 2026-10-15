-- VIEW 1: StaffScheduleView
-- Provides a readable summary of every staff member's
-- scheduled shifts across all departments. 


CREATE VIEW StaffScheduleView AS
SELECT
    s.StaffID,
    CONCAT(s.FirstName, ' ', s.LastName) AS StaffName,
    s.RoleType,
    d.Dept_Name AS Department,
    ss.ShiftType,
    ss.StartDateTime,
    ss.EndDateTime,
    ROUND(TIMESTAMPDIFF(MINUTE, ss.StartDateTime, ss.EndDateTime) / 60, 2) AS HoursWorked
FROM  StaffSchedule ss
JOIN  Staff s ON ss.StaffID = s.StaffID
JOIN  Department d ON ss.DepartmentID = d.DepartmentID;


-- VIEW 2: ProcedureFrequency
-- Tracks how often each unique procedure code has been
-- performed and which doctor performed it. 

-- BUG FIXED (V4 -> V5):
-- The original JOIN on Staff was JOIN Staff s ON pt.PerformedByStaffID, 
-- Corrected version: JOIN Staff s ON pt.PerformedByStaffID = s.StaffID


CREATE VIEW ProcedureFrequency AS
SELECT
    pt.ProcedureCode,
    pt.Procedure_Description AS ProcedureName,
    COUNT(*) AS TotalTimesPerformed,
    CONCAT(s.FirstName, ' ', s.LastName) AS PerformedByDoctor
FROM  Procedure_Table pt
JOIN  Encounter e ON pt.EncounterID = e.EncounterID
JOIN  Patient p ON e.PatientID = p.PatientID
JOIN  Staff s ON pt.PerformedByStaffID = s.StaffID   -- FIXED: was missing = s.StaffID
GROUP BY
    pt.ProcedureCode,
    pt.Procedure_Description,
    s.StaffID,
    s.FirstName,
    s.LastName;
