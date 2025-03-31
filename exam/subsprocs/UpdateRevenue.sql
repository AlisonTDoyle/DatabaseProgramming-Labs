SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [S00233102].[UpdateRevenue]
-- external variables
@EExcursionRevenue MONEY
, @EExhibitId INT
as
-- Transactional/Business logic
-- set revue value
UPDATE ExhibitTBL
SET ExhibitRevenue = ExhibitRevenue + @EExcursionRevenue
WHERE ExhibitID = @EExhibitId
-- Success message
GO
