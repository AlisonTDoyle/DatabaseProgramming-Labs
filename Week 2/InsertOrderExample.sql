alter proc [dbo].[MasterOrder2021V1]
--external variables
@EcustomerID int, @ePONumber int, @EOrderDetails details readonly
as
--Declare internal variables
Declare @IEnoughCreditLimit money, @IEnoughStock smallint
, @ICostOfOrder money, @IOrderDetails IorderDetails
,@OOrderNo int
-- now perform the necessary reads
-- get the credit limit for the customer
select @IEnoughCreditLimit = CreditLimit
from dbo.CustomerTBL
where CustomerID = @EcustomerID
-- is there enough stock for all the items being ordered
select @IEnoughStock= count(*)
from dbo.ProductTBL as p
join @EOrderDetails as ed on
p.ProductID=ed.ProductID
where isnull(p.Quantity,0) < ed.OrderQty
-- what is the cost of the order
SELECT @ICostOFOrder = sum(((p.UnitPrice*ed.OrderQty)-ed.Discount))
FROM dbo.ProductTBL AS p
join @EOrderDetails AS ED ON
p.ProductID = ed.ProductID
-- now do business logic
if @IEnoughCreditLimit<@ICostOfOrder
begin
;throw 500001, 'CustomerCreditLimit is exceeded order is refused', 1
end

If @IEnoughStock >0
begin
;throw 500001, 'Not enough stock order is refused', 1
End


begin try
exec InsertOrder @eCustomerID, @EPoNumber
, @EOrderNo=@OOrderNo output
end try
begin catch
;throw
end catch



-- now we need to update the @IOrderDetails variable with all the column data
-- first insert the 3 columns for the external table variable
insert into @IOrderDetails
(ProductID, OrderQty, Discount)
select *
from @EOrderDetails

-- then update the order no column
Update @IOrderDetails
set OrderNo = @OOrderNo

-- finally update the price for each product being ordered
update @IOrderDetails
set Price = unitPrice
from dbo.ProductTBL as p
inner join @IOrderDetails as od on
p.ProductID=od.ProductID

-- phew we got to insert the order details
-- so execute the sub sproc
begin try
exec InsertOrderDetails @IOrderDetails
end try
begin catch
;throw
end catch

raiserror ('yes order has been inserted', 16, 1)
return 0