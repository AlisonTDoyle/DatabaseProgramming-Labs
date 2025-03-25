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
set transaction isolation level repeatable read
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
        -- how many patients are there on this ward
        select @INoOfPatients=COUNT(*)
        from dbo.PatientTbl
        where PatientWard = @EWardID
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
        -- Do The Logic
        -- get the patients age
        if MONTH(@EDOB) <= MONTH(getdate()) and day(@EDOB) <= day(getdate())
        begin
            select @IAge = DATEDIFF(yy, @EDOB, getdate())
        end
        else 
        begin
            select @iage = (DATEDIFF(yy, @EDOB, getdate()))-1
        end
        --is the ward full and its not a weekend
        if @IWardcapacity<=@INoOfPatients
        begin
        if @iday not like 'sunday' and @IDay not like 'saturday'
        begin
            select @IName= Upper(substring(@EFname,1,1)) + SUBSTRING(@EFname,2,len(@EFname))
            +' '+Upper(substring(@ELname,1,1)) + SUBSTRING(@ELname,2,len(@ELname))
            select @msgtext =  N'This ward is overflowing – find a different ward for %s'
            select @msg = FORMATMESSAGE (@msgtext,  @IName);   
            ;THROW 50001, @msg, 1 
        end
        else 
            --is the ward at 120% capacity and it is a weekend
            if ceiling((@IWardcapacity*1.2))<=@INoOfPatients
            begin
                select @IName= Upper(substring(@EFname,1, 1)) + SUBSTRING(@EFname,2,len(@EFname))
                +' '+Upper(substring(@ELname,1,1)) + SUBSTRING(@ELname,2,len(@ELname))
                select @msgtext = N'This ward is overflowing – find a different ward for %s'
                select @msg = FORMATMESSAGE (@msgtext,  @IName);   
                ;THROW 50001, @msg, 1 
            end
        end
        -- what about the age rules
        SELECT @msgtext =
        CASE
            -- less that or equal to 13
            WHEN @IAge <= 13 and 
            (
            @Iwardspec not LIKE '%Paeds13%' 
            and @IWardspec not LIKE '%Paediatrics13%' 
            )
            THEN N'Patients in this ward must be 13 or younger'
            --age > 13 and M 15 ==> 14 years old check
            when @IAge = 14 and
            (
            @Iwardspec not LIKE '%Paeds15%' 
            and @IWardspec not LIKE '%Paediatrics15%' 
            )
            THEN N'Patients in this ward must be 14'
            --aged between 15 and 18 check
            when @IAge between 15 and 18 
            and 
            (
            @IWardspec not  like '%paeds%'
            or (@Iwardspec like '%paeds13%' or @IWardspec like '%paeds15%'
            OR @Iwardspec   like '%paediatrics13%' 
            OR @IWardspec like '%paediatrics15%' 
            )
            )
            then  N'Patients between 15 and 18 not allowed in this ward'
            when @IAge >18
            and 
            (
            @IWardspec  like '%paeds%'
            or (@Iwardspec like '%paeds13%' or @IWardspec like '%paeds15%'
            OR @Iwardspec   like '%paediatrics13%' 
            OR @IWardspec like '%paediatrics15%' 
            )
            )
            then  N'Adults are not allowed on Children''s ward'
            else NUll
        END
        --if one of the ages causes a fail finish here
        IF @msgtext IS NOT NULL
        BEGIN
            select @msg = FORMATMESSAGE (@msgtext);   
            ;THROW 50001, @msg, 1 
        END
        --Now Do Care Team Rules
        --is there a nurse with the speciality
        if @INoOfSpecNurses = 0
            Begin
            SELECT @ICareTeamFlag = 0
            raiserror ('no nurse has the required speciality', 16,1)
        end
        -- is there a doctor with the speciality
        if @INoofDoctors = 0
            Begin
            SELECT @ICareTeamFlag = 0
            raiserror ('no doctor has the required speciality', 16,1)
        end
        --enough current members for Covid Positive?
        if (@INoOfNurses<3 or @INoofDoctors< 1) and @ECovidStatus not like 'Positive' and @IAddNurseP is null
        begin
            SELECT @ICareTeamFlag = 0
            raiserror ('not enough members available for the team', 16,1)
        end
        -- enough current members for Covid Negative?
        if (@INoOfNurses<3 or @INoofDoctors< 1) and @ECovidStatus  like 'Negative' and @IAddNursen is null
        begin
            SELECT @ICareTeamFlag = 0
            raiserror ('not enough members available for the team', 16,1)
        end
        --OK Business Rules have been passed
        --Call other procs to do the inserts
        --insert the patient
        begin try
            exec dbo.InsertPatient @eFname, @ELname, @EWardID, @ECovidStatus, @EPatientId=@IPatientID output
        end try
        begin catch
            ;throw
        end catch
        -- add the nurse to the care team if there is one available
        If @IAddNurseN is not null
        begin
            begin try
                exec dbo.InsertNurse @ECareTeamID, @IAddNurseN
            end try
            begin catch
                ;throw
            end catch
        end
        If @IAddNurseP is not null
        begin
            begin try
                exec dbo.InsertNurse @ECareTeamID, @IAddNurseP
            end try
            begin catch
                ;throw
            end catch
        end
        -- Assign the Patient to the Care Team if allowed 
        if @ICareTeamFlag = 1
            begin try
                exec dbo.InsertIntoCareTeam @eCareteamID, @IPatientID
            end try
                begin catch
                ;throw
            end catch
            --all ok do a cleanup of tem table
            DROP TABLE #t1;
            DROP TABLE #t2;
            -- got here let them know
            raiserror ('The Patient has been admitted',16,1)
            return 0
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