/*
@skuIDs = string.Join(at.Spr.Comma, skuIDs);
*/
--Aimee
CREATE FUNCTION [svc].[Sku$VerifyForEndorsement](@skuIDs nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	SkuID=x.Piece, Result=isnull(cast(s.ID as bigint), 0)
	from	tvp.Comma#Slice(@skuIDs) x
	left	join invt.Sku#Raw()      s on s.ID=x.Piece
)
