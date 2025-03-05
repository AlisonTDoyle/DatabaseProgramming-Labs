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
, @ECareTeamId INT
as
-- INTERNAL VARIABLES
Declare 
@IDayOfTheWeek VARCHAR(9)
, @IWardCapacity INT
, @IWardCapacityForToday INT
, @ICurrentWardPatientCount TINYINT
, @IUpdateWardStatus BIT
, @IPatientAge TINYINT
, @IWardSpeciality CHAR(10)
, @ICareTeamsDoctors CareTeamDoctorsUDT
, @INewPatientId INT
-- READ DATA AND POPULATE INTERNAL VARIABLES
-- get day of the week
SELECT @IDayOfTheWeek = DATENAME(WEEKDAY, GETDATE())
-- get default capacity for ward
SELECT @IWardCapacity = WardCapacity
FROM [dbo].[WarDTBL]
WHERE WardID = @EWardId
-- get current no. of patients on ward
SELECT @ICurrentWardPatientCount = COUNT(*)
FROM [dbo].PatientTBL
WHERE PatientWarD = @EWardId
-- get selected ward speciality
SELECT @IWardSpeciality = WardSpeciality
FROM [dbo].[WarDTBL]
WHERE WardID = @EWardId
-- get relevent doctors
INSERT INTO @ICareTeamsDoctors
(DoctorId, CareTeamId, DoctorSpecialty, Covid19Vaccinated)
SELECT d.DoctorID, ct.CareTeamID, d.DoctorSpeciality, d.COVID19Vacinated
FROM DoctorCareTeamMembersTBL as ct
INNER JOIN DoctorTBL as d
on ct.MemberID = d.DoctorID
WHERE CareTeamID = @ECareTeamId
-- BUSINESS LOGIC
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
-- check if patient will breach capacity
IF ((@ICurrentWardPatientCount + 1) > @IWardCapacityForToday)
BEGIN
-- alert user to ward capacity breach
;throw 500001, 'Patient breaches ward capacity', 1
END
-- check if ward is starting to overflow (only applicable to weekends)
IF UPPER(@IDayOfTheWeek) = 'SATURDAY' OR UPPER(@IDayOfTheWeek) = 'SUNDAY'
BEGIN
IF (((@ICurrentWardPatientCount + 1) > @IWardCapacity) AND ((@ICurrentWardPatientCount + 1) <= @IWardCapacityForToday))
BEGIN
SELECT @IUpdateWardStatus = 1
END
END
-- calculate patient age
SELECT @IPatientAge = DATEDIFF(YEAR, @EPatientDateOfBirth, GETDATE())
PRINT 'Patient Age: ' + CAST(@IPatientAge AS NVARCHAR(10));
-- check if patient is being assigned to the right ward
PRINT CONCAT('Speciality: ', @IWardSpeciality);
-- check for paed ward
IF (UPPER(@IWardSpeciality) LIKE 'PAEDIATRIC' OR UPPER(@IWardSpeciality) LIKE 'PAEDS')
BEGIN
IF (@IPatientAge > 18 OR @IPatientAge < 15)
BEGIN
;THROW 500002, 'Attempted to assign patient to a ward for patients between 15 and 18 years of age', 1
END
END
-- check for paed15 ward
IF (UPPER(@IWardSpeciality) LIKE 'PAEDIATRIC15' OR UPPER(@IWardSpeciality) LIKE 'PAEDS15')
BEGIN
IF (@IPatientAge >= 15 OR @IPatientAge <= 13)
BEGIN
;THROW 500003, 'Attempted to assign patient to a ward for patients between 13 and 15 years of age', 1
END
END
-- check for paed13 ward
IF (UPPER(@IWardSpeciality) LIKE 'PAEDIATRIC13' OR UPPER(@IWardSpeciality) LIKE 'PAEDS13')
BEGIN
IF (@IPatientAge > 13)
BEGIN
;THROW 500004, 'Attempted to assign patient to a ward for patients under 13 years of age', 1
END
END
-- check if patient has covid
IF (UPPER(@EPatientCovidStatus) LIKE 'POSITIVE')
BEGIN
print('check all team members')
END
-- SUBSPROCS
-- check if ward status needs updating to overflow
IF (@IUpdateWardStatus = 1)
BEGIN
EXEC UpdateWardStatus @EWardId
END
-- record new patient and capture their id
EXEC InsertPatient @EPatientFirstName, @EPatientLastName, @EWardId, @EPatientCovidStatus, @EPatientId = @INewPatientId
-- assign patient to care team in CareTeamTBL
EXEC InsertIntoCareTeam @ECareTeamID, @INewPatientId
-- SUCCESS MESSAGE
print 'Patient successfully recorded'
GO

-- NOTE: Need to do:
-- change CareTeamTBL priary key to comp. key w/ CareTeamID & PatientID 
-- common table expression
-- order by new id
-- assign a nurse to any care team that doesnt have a nurse