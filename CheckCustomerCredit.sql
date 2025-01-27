SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [JuneExam2024Practice].[CheckCustomerCredit]
-- External variables
@ECustomerId INT
, @EProductId INT
, @EQuantityBeingOrdered INT
AS
-- Internal variables
DECLARE @ICreditLimit INT
, @IProductCost MONEY
, @IOrderCost INT;
-- Read data and populate internal vars
-- get credit limit of customer
SELECT @ICreditLimit = CustomerTBL.CreditLimit
FROM dbo.CustomerTBL
WHERE CustomerID = @ECustomerId;
-- get product cost
SELECT @IProductCost = ProductTBL.UnitPrice
FROM dbo.ProductTBL
WHERE ProductID = @EProductId;
-- Transactional/Business logic
-- calculate order cost
SELECT @IOrderCost = @EQuantityBeingOrdered * @IProductCost;
-- Transactional/Business logic
-- check if order cost is greater than customer credit
IF (@IOrderCost > @ICreditLimit)
BEGIN
    ;throw 50001, 'You do not have enough credit :(',1;
END
-- Subsprocs
-- Success message
PRINT 'You have enough credit! :)'
GO
