SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[InsertNurse]
-- external variables
@ECareTeamId int
, @ENurseId int
as
-- internal variables
DECLARE @ITodaysDate smalldatetime
-- business logic
-- get todays date to record date nurse joined
SELECT @ITodaysDate = GETDATE()
BEGIN TRY
-- link new nurse and care team through NurseCareTeamMembersTBL
INSERT INTO dbo.NurseCareTeamMembersTBL
(CareTeamID, MemberID, DateJoineD, CurrentMember)
VALUES
(@ECareTeamId, @ENurseId, @ITodaysDate, 1)
END TRY
BEGIN CATCH
;throw
END CATCH
-- success message
RAISERROR ('Patient has been inserted', 16, 1)
GO
