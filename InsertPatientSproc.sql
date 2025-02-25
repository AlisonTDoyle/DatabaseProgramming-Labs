SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[InsertPatient]
-- external variables
@EPatientFirstName varchar(35)
, @EPatientLastName varchar(35)
, @EWardId int
, @ECovidStatus char(8)
AS
-- business logic
BEGIN TRY
INSERT INTO dbo.PatientTBL 
(PatientFname, PatientLname, PatientWarD, PatientCOVIDStatus)
VALUES
(@EPatientFirstName, @EPatientLastName, @EWardId, @ECovidStatus)
END TRY
BEGIN CATCH
;throw
END CATCH
RAISERROR ('Patient has been inserted', 16, 1)