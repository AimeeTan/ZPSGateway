CREATE FUNCTION [loc].[TotalSkuQty#For](@declaredInfo nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	TotalSkuQty=sum(l.LineQty)
	from	tvp.Mucho#Slice(@declaredInfo) x
	cross	apply loc.LineInfo#Of(x.Piece) l
)
