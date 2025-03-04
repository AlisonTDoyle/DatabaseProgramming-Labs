SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[InsertIntoCareTeam]
-- external vairables
@ECareTeamIDs PatientCareTeamsUDT READONLY
, @EPatientId int
as
-- business logic
BEGIN TRY
-- assign patient to care team
UPDATE dbo.CareTeamTBL
SET PatientID = @EPatientId
WHERE CareTeamID = (
    SELECT CareTeamID
    FROM @ECareTeamIDs 
)
END TRY
BEGIN CATCH
;THROW
END CATCH
-- success message
RAISERROR ('Patient has been assigned to care team', 16, 1)