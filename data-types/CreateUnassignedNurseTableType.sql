CREATE TYPE [UnassignedNursesUDT] AS TABLE
(
    [NurseId] [INT] NOT NULL
    , [NurseSpeciality] [VARCHAR](50) NULL
    , [NurseWard] [INT] NULL
    , [Covid19Vaccinated] [BIT] NULL
)