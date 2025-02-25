SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[InsertIntoCareTeam]
-- external vairables
@ECareTeamId INT
, @EPatientId int
as
-- business logic
BEGIN TRY
INSERT INTO dbo.PatientTBL 
(PatientFname, PatientLname, PatientWarD, PatientCOVIDStatus)
VALUES
(@EPatientFirstName, @EPatientLastName, @EWardId, @ECovidStatus)
END TRY
BEGIN CATCH
END CATCH
-- success message