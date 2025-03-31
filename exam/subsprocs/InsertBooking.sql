SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [S00233102].[InsertBooking]
    -- external variables
    @EExhibitionDetails ExcursionList READONLY
as
-- Transactional/Business logic
BEGIN TRY
INSERT INTO ExcrsionDetailsTBL
    ([VisitorFirstName]
    ,[VisitorLastname]
    ,[MobilePhoneNumber]
    ,[ExcursionID])
select *
from @EExhibitionDetails
END TRY
BEGIN CATCH
;THROW
END CATCH
GO
