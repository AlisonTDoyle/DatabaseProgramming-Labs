SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[InsertPatient]
-- external variables
@EPatientFirstName VARCHAR(35)
, @EPatientLastName VARCHAR(35)
, @EWardId INT
, @ECovidStatus CHAR(8)
, @EPatientId INT OUTPUT
AS
-- business logic
BEGIN TRY
-- insert patient
INSERT INTO dbo.PatientTBL 
(PatientFname, PatientLname, PatientWarD, PatientCOVIDStatus)
VALUES
(@EPatientFirstName, @EPatientLastName, @EWardId, @ECovidStatus)
-- capture inserted patient id
SELECT @EPatientId = SCOPE_IDENTITY()
END TRY
BEGIN CATCH
;throw
END CATCH
RAISERROR ('Patient has been inserted', 16, 1)