--Smile
CREATE FUNCTION [svc].[CourierAlias$Verify](@aliasInCsv nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=c.CourierID, CourierAlias=x.Piece
	from	tvp.Comma#Slice(@aliasInCsv)          x
	cross	apply tms.Courier#IdOfAlias(x.Piece)  c
)