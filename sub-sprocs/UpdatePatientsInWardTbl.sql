SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[UpdatePatientInWardTBL]
-- external variables
@EWardId int
as
-- business logic
BEGIN TRY
-- change ward status
UPDATE WarDTBL
SET PatientsOnWard = PatientsOnWard + 1
WHERE WardID = @EWardId
END TRY
BEGIN CATCH
;THROW
END CATCH
-- success message
RAISERROR ('No. of Patients on ward updated', 16, 1)
GO
