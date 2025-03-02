SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[ExamMaster]
-- EXTERNAL VARIABLES
@EPatientFirstName VARCHAR(35)
, @EPatientLastName VARCHAR(35)
, @EPatientDateOfBirth DATE
, @EPatientCovidStatus char(8)
, @EWardId INT
, @ECareTeamIDs INT -- need to update
as
-- INTERNAL VARIABLES
Declare 
@IDayOfTheWeek VARCHAR(9)
, @IWardCapacity INT
, @IWardCapacityForToday INT
, @ICurrentWardPatientCount TINYINT
-- READ DATA AND POPULATE INTERNAL VARIABLES
-- get day of the week
SELECT @IDayOfTheWeek = DATENAME(WEEKDAY, GETDATE())
-- get default capacity for ward
SELECT @IWardCapacity = WardCapacity
FROM [dbo].[WarDTBL]
WHERE WardID = @EWardId
-- calculate todays capacity
IF UPPER(@IDayOfTheWeek) = 'SATURDAY' OR UPPER(@IDayOfTheWeek) = 'SUNDAY'
BEGIN
-- if weekend, take into account increased capacity
SELECT @IWardCapacityForToday = @IWardCapacity * 1.2
END
ELSE
BEGIN
-- if weekday, capacity is normal
SELECT @IWardCapacityForToday = @IWardCapacity
END
-- get current no. of patients on ward
SELECT @ICurrentWardPatientCount = COUNT(*)
FROM [dbo].PatientTBL
WHERE PatientWarD = @EWardId
-- BUSINESS LOGIC
-- check if patient will breach capacity
IF ((@ICurrentWardPatientCount + 1) > @IWardCapacityForToday)
BEGIN
-- alert user to ward capacity breach
;throw 500001, 'Patient breaches ward capacity', 1
END
-- CHECK IF WARD HAS CAPACITY FOR NEW PATIENT
-- SUBSPROCS
-- SUCCESS MESSAGE
GO
