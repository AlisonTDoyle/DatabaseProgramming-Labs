-- ward capacity rule test
-- insert patient into full ward
BEGIN TRY
    PRINT 'insert patient into full ward'
    EXEC [dbo].ExamMaster "jack", "underkofler", "2005-03-01", "Negative", 1, 1
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- ward age rules tests
-- insert patient under 13 into appropriate ward
BEGIN TRY
    PRINT ' '
    PRINT 'insert patient under 13 into appropriate ward'
    EXEC [dbo].ExamMaster "Jane", "Doe", "2013-03-01", "Negative", 2, 2
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- insert patient under 13 into inappropriate ward (15-18 yrs old)
BEGIN TRY
    PRINT ' '
    PRINT 'insert patient under 13 into inappropriate ward (15-18 yrs old)'
    EXEC [dbo].[ExamMaster] "John", "Doe", "2016-03-01", "Negative", 3, 1
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- care team rules tests
-- insert patient with care team with no doctor
BEGIN TRY
    PRINT ' '
    PRINT 'insert into care team with no doctor'
    EXEC [dbo].[ExamMaster] "No", "Doctor", "2008-03-01", "Negative", 4, 3
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- insert patient with care team with no nurse
BEGIN TRY
    PRINT ' '
    PRINT 'insert into care team with no nurse'
    EXEC [dbo].[ExamMaster] "No", "Nurse", "2008-03-01", "Negative", 4, 4
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- insert patient with care team with 1 nurse
BEGIN TRY
    PRINT ' '
    PRINT 'insert into care team with 1 nurse'
    EXEC [dbo].[ExamMaster] "One", "Nurse", "2008-03-01", "Negative", 4, 5
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- insert patient with covid with an unvaccinated doctor
BEGIN TRY
    PRINT ' '
    PRINT 'insert into care team with unvaccinated doctor'
    EXEC [dbo].[ExamMaster] "unvac", "Doe", "2008-03-01", "POSITIVE", 4, 6
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- insert patient with covid with an unvaccinated doctor
BEGIN TRY
    PRINT ' '
    PRINT 'insert into care team with unvaccinated nurse'
    EXEC [dbo].[ExamMaster] "unvac", "nurse", "2008-03-01", "Positive", 4, 8
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH
-- insert patient with doctor with incorrect speciality
BEGIN TRY
    PRINT ' '
    PRINT 'insert into care team with doctor with incorrect speciality'
    EXEC [dbo].[ExamMaster] "incorrect", "speciality", "2008-03-01", "Positive", 4, 9
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE()
END CATCH