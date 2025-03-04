SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[UpdateWardStatus]
-- external variables
@EWardId int
as
-- business logic
BEGIN TRY
-- change ward status
UPDATE WarDTBL
SET WardStatus = 'Overflow'
WHERE WardID = @EWardId
END TRY
BEGIN CATCH
;THROW
END CATCH
-- success message
RAISERROR ('Ward status updates to "overflow"', 16, 1)
GO
