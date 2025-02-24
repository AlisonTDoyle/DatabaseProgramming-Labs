SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[ExamMaster]
-- external variables
@EPatientFirstName VARCHAR(35)
, @EPatientLastName VARCHAR(35)
, @EPatientDateOfBirth DATE
, @EPatientCovidStatus char(8)
, @EWardId INT
, @ECareTeamIDs INT -- need to update
as
-- internal variables
Declare @IPatientsOnWard TINYINT
, @IWardCapacity TINYINT
, @IWardSpecialty TINYINT
, @INoOfNursesWithSpeciality INT -- need to update
, @INoOfNursesVaccinated INT -- need to update
, @INoOfNursesActiveOnLessThan3Wards INT -- need to update
, @INoOfNursesOnCareTeam INT -- need to update
, @INursesWithoutWardOrCareTeamVaccinated INT -- need to update
, @INursesWithoutWardOrCareTeamUnvaccinated INT -- need to update
, @INoOfDocorsOnCareTeam INT -- need to update
, @INoOfDoctorsVaccinated INT  -- need to update
, @INoOfDoctorsWithSpecialty INT -- need to update
, @IPatientAge INT
, @IDayOfWeek VARCHAR(7)
-- read data and populate internal vars
-- business logic
-- subsprocs
-- success message
GO
