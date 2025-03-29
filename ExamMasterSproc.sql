SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[ExamMaster]
    -- external variables
    @EFname varchar(35),
    @ELname varchar(35),
    @EDOB date,
    @EWardID int,
    @ECareteamID int,
    @ECovidStatus varchar(20)
as
set transaction isolation level serializable
-- internal variables
declare @IWardcapacity tinyint, 
@IWardspec varchar (25),
@INoOfPatients tinyint, 
@INoofDoctors tinyint,
@INoOfNurses tinyint,
@INoOfSpecNurses tinyint, 
@IDay varchar(12),
@IAge tinyint, 
@IPatientID int, 
@ICareTeamFlag bit = 1, 
@IName varchar(100), 
@msgtext varchar(1000), 
@msg varchar(1000), 
@IAddNurseN int, 
@IAddNurseP int,
@IRetryCount int = 0
set nocount on
-- allow initial attempt and up to 3 re-attempts to complete transaction
while (@IRetryCount <= 3)
BEGIN
    -- try block to catch any deadlock errors
    BEGIN TRY
        -- (DEBUGGING) record how many attempts where completed
        PRINT CONCAT('Attempt No. ', CAST(@IRetryCount as varchar(20)))
        -- start transaction
		BEGIN TRANSACTION
        -- do the reads
        --read the data from the ward table
        select @IWardcapacity=WardCapacity
        , @IWardspec=WardSpeciality
        from dbo.WardTbl
        where WardID=@EWardID
        -- how many patients are there on this ward (use denormalised column)
        SELECT @INoOfPatients = PatientsOnWard
        FROM dbo.WardTbl
        WHERE WardID = @EWardID
        -- how many nurses are there on this care team
        select @INoOfNurses = COUNT(*)
        from dbo.NurseCareTeamMembersTBL
        where CareTeamID=@ECareteamID
        and CurrentMember = 1
        -- how many nurses are there on this care team who have the speciality
        select @INoOfSpecNurses =count(*)
        from dbo.NurseCareTeamMembersTBL as nc
        join dbo.NurseTBL  as n on
        nc.MemberID= n.NurseID
        where CareTeamID=@ECareteamID
        and
        SUBSTRING(NurseSpeciality,(len(NurseSpeciality)-2),3) like SUBSTRING(@IWardspec,1,3)
        and 
        CurrentMember = 1
        -- how many doctors are there on this care team 
        --who have the speciality
        select @INoofDoctors = COUNT(*)
        from dbo.DoctorTbl as d
        inner join dbo.DoctorCareTeamMembersTBL  as dc on
        d.DoctorID=dc.MemberID
        where CareTeamID=@ECareteamID
        and
        SUBSTRING(DoctorSpeciality,(len(DoctorSpeciality)-2),3) like SUBSTRING(@IWardspec,1,3)
        and CurrentMember = 1
        -- what day of the week is it
        select @IDay=DATENAME(dw,getdate())
        --now populate the temp tables with available nurses from the ward
        -- who are not active on 3 care teams
        select NurseID
        into #t1
        from dbo.NurseTBL as n
        join dbo.NurseCareTeamMembersTBL as c on
        n.NurseID=c.MemberID
        where CurrentMember = 1
        and NurseWard = @EWardID
        AND NURSEID NOT IN
        (SELECT MemberID
        FROM DBO.NurseCareTeamMembersTBL
        where  CurrentMember=@ECareteamID
        )
        group by NurseID
        having count(*) <3
        -- add in those not assinged to a care team 
        -- and have not been assinged to a ward
        -- and have not been vaccinated
        union
        select NurseID
        from dbo.NurseTBL as n
        left join dbo.NurseCareTeamMembersTBL as nc on
        n.NurseID=nc.MemberID
        where 
        nc.MemberID is null
        and NurseWard is null
        and COVID19Vacinated = 0
        -- randomly select a nurse from this table
        select top 1 @IAddNurseN = NurseID
        from #t1
        order by newid()
        -- now repeat this but this time 
        -- get nurses that have been vaccinated
        select NurseID
        into #t2
        from dbo.NurseTBL as n
        join dbo.NurseCareTeamMembersTBL as c on
        n.NurseID=c.MemberID
        where CurrentMember = 1
        and NurseWard = @EWardID
        AND NURSEID NOT IN
        (SELECT MemberID
        FROM DBO.NurseCareTeamMembersTBL
        where  CurrentMember=@ECareteamID
        and CareTeamID=1)
        group by NurseID
        having count(*) <3
        -- add in those not assinged to a care team 
        -- and have not been assinged to a ward
        -- and have  been vaccinated
        union
        select NurseID
        from dbo.NurseTBL as n
        left join dbo.NurseCareTeamMembersTBL as nc on
        n.NurseID=nc.MemberID
        where 
        nc.MemberID is null
        and NurseWard is null
        and COVID19Vacinated = 1
        -- now randomly select from this list
        select top 1 @IAddNurseP = NurseID
        from #t2
        order by newid()
        -- (DEBUGGING)
        WAITFOR DELAY '00:00:05'
        EXEC dbo.UpdatePatientInWardTBL @EWardID
        -- if everything goes as intended, commit transaction
        COMMIT TRANSACTION 
        -- when transaction is complete, end loop
        BREAK
    END TRY
    -- handle any errors
    BEGIN CATCH
        -- check if deadlock occured
        IF (ERROR_NUMBER() = 1205)
        BEGIN
            -- let user know a deadlock occured
            PRINT 'Error: Deadlock has occured'
            -- undo any changes made in previous attempt
            ROLLBACK TRANSACTION
            -- prepare for reattempt
            SET @IRetryCount = @IRetryCount + 1
            CONTINUE
        END
        ELSE
        BEGIN
            -- handle any other type of errors
            ROLLBACK TRANSACTION
            ;throw
        END
    END CATCH
END
-- return success or failure message to user
IF @IRetryCount <= 3
BEGIN
    RAISERROR ('Success: Patient was recorded.', 16, 1)
END
ELSE
BEGIN
    RAISERROR ('Error: Patient not recorded. Database has too high of usage currently. Please try again later.', 16, 1)
END