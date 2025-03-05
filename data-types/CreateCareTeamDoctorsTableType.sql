CREATE TYPE [CareTeamDoctorsUDT] AS TABLE
(
    [DoctorId] [INT] NOT NULL
    , [CareTeamId] [INT] NOT NULL
    , [DoctorSpecialty] [VARCHAR](50) NULL
    , [Covid19Vaccinated] [BIT] NULL
)