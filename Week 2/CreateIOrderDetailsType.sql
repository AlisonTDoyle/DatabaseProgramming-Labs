CREATE TYPE [dbo].[IOrderDetails] AS TABLE(
	[OrderNo] [int] NULL,
	[ProductID] [int] NULL,
	[OrderQty] [smallint] NULL,
	[Price] [money] NULL,
	[Discount] [money] NULL
)