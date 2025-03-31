SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [S00233102].[ExamMasterSproc]
-- EXTERNAL VARIABLES
@EExcursionDetails ExcursionList READONLY
AS
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
-- INTERNAL VARIABLES
DECLARE @IAttemptCounter int = 0
, @IAllowedReattempts tinyint = 5
, @IExcurtionId int
, @IExhibitId int
, @IExhibitionLocation VARCHAR(50)
, @IVisitorsAttending INT
, @IVisitorToStaffRatio TINYINT
, @IStaffAssignedToRoom INT
, @IExcursionTicketId int
, @IBookingValue MONEY
, @ITicketPrice DECIMAL(10,2)
-- turn off unecessary messaging 
SET NOCOUNT ON
-- ALLOW INITIAL AND REATTEMPTS OF TRANSACTION
WHILE (@IAttemptCounter <= @IAllowedReattempts)
BEGIN
BEGIN TRY 
	-- mark the beginning of the transaction
	BEGIN TRANSACTION
        -- READ DATA INTO INTERNAL VARIABLES
        -- get id of excursion being attended
        SELECT @IExcurtionId = ExcursionID
        FROM @EExcursionDetails
        -- get id of exhibit
        SELECT @IExhibitId = ExhibitId
        FROM ExcursionTBL
        WHERE ExcursionID = @IExcurtionId
        -- get location of related exhibit
        SELECT @IExhibitionLocation = e.Location
        FROM ExhibitTBL as e
        WHERE ExhibitId = @IExhibitId
        -- get no of visitors attending
        SELECT @IVisitorsAttending = COUNT(*)
        FROM @EExcursionDetails
        -- get no of staff in room
        SELECT @IStaffAssignedToRoom = COUNT(*)
        FROM ExhibitionStaffTBL
        WHERE ExhibitID = @IExhibitId
        -- get ticket id of excursion
        SELECT @IExcursionTicketId = TicketID
        FROM ExcursionTBL
        WHERE ExcursionID = @IExcurtionId
        -- get ticket prict of excursion
        SELECT @ITicketPrice = Price
        FROM TicketTBL
        WHERE TicketID = @IExcursionTicketId
        -- BUSINESS LOGIC
        -- select appropriate ratio of visitors to staff
        SELECT @IVisitorToStaffRatio =
        CASE
        -- check for main hall
        WHEN Upper(@IExhibitionLocation) LIKE 'MAIN HALL'
        THEN 7
        -- check for gallery a
        WHEN Upper(@IExhibitionLocation) LIKE 'GALLERY A'
        THEN 5
        -- check for exhibition room b
        WHEN Upper(@IExhibitionLocation) LIKE 'EXHIBITION ROOM B'
        THEN 3
        -- check for gallery a
        WHEN Upper(@IExhibitionLocation) LIKE 'NORTH WING'
        THEN 2
        END
        -- check if enough staff are in room
        IF (@IStaffAssignedToRoom < CEILING(@IVisitorsAttending / @IVisitorToStaffRatio))
        BEGIN
            ;THROW 50001, 'Error: Not enough staff for visitors', 1
        END
        -- calculate the revenue from excursion
        SELECT @IBookingValue = @ITicketPrice * @IVisitorsAttending
        -- EXECUTE SUBSPROCS
        -- add visitors to db
        BEGIN TRY
            EXEC InsertBooking @EExcursionDetails
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION
            ;throw
        END CATCH
        -- update revenue
        BEGIN TRY
            EXEC UpdateRevenue @IBookingValue, @IExhibitId
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION
            ;throw
        END CATCH
	-- everythis is ok so commit the transaction
	COMMIT transaction 
	-- transaction has committed so break out of the loop
	break
END TRY
-- handle any errors
    BEGIN CATCH
        -- check if deadlock occured
        IF (ERROR_NUMBER() = 1205)
        BEGIN
            -- let user know a deadlock occured
            PRINT 'Error: Deadlock has occured. Reattempting request...'
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
-- RETURN SUCCESS OR FAILURE MESSAGE TO USER
IF (@IAttemptCounter <= @IAllowedReattempts)
BEGIN
    RAISERROR ('Success: Booking was recorded.', 16, 1)
END
ELSE
BEGIN
    RAISERROR ('Error: Booking not recorded. Database has too high of usage currently. Please try again later.', 16, 1)
END
GO
