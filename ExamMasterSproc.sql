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
        -- record how many attempts where completed
        PRINT CONCAT('Attempt No. ', CAST(@IRetryCount as varchar(20)))
        -- Mark the beginning of the transaction
		BEGIN TRANSACTION

		-- Read in a value from the table 
		DECLARE @bal INT
		SELECT @bal = Quantity
		FROM dbo.ProductTBL
		WHERE ProductID = 100

		-- Put in a wait to mimic some processing
		WAITFOR DELAY '00:00:05'

		-- Update the value in the table
		UPDATE dbo.ProductTBL
		SET Quantity = @bal + 50
		WHERE ProductID = 100

		-- Everything is OK, so commit the transaction
		COMMIT TRANSACTION 

		-- Transaction has committed, so break out of the loop
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