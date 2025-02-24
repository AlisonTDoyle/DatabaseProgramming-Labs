create proc [dbo].[InsertOrder]
@ECustomerID int
, @EPONumber int
, @EOrderNo int output
as
Begin try
insert into dbo.OrderTBL
(CustomerID, OrderDate, PurchaseOrderID)
values
(@ECustomerID, getdate(), @EPONumber)
select @EOrderNo=SCOPE_IDENTITY()
end try
begin catch
;throw
end catch
