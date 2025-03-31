CREATE TYPE [CareTeamNursesUDT] AS TABLE
(
    [NurseId] [INT] NOT NULL
    , [CareTeamId] [INT] NOT NULL
    , [NurseSpeciality] [VARCHAR](50) NULL
    , [NurseWard] [INT] NULL
    , [Covid19Vaccinated] [BIT] NULL
)