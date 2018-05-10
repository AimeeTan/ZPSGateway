-- Smile
CREATE FUNCTION [hub].[Parcel$ShippingPlanInfo](@number varchar(40))
RETURNS TABLE
--, ENCRYPTION
WITH SCHEMABINDING
AS RETURN 
(
	select	ID=x.MatterID, Seq=b.Seq, ParcelItem=b.Piece
	from	core.RefNbr#ScanOne(@number, default, default)        x
	cross	apply core.RefInfo#Type()                             t
	cross	apply core.RefInfo#Of(x.MatterID, t.ShippingPlanInfo) i
	cross	apply tvp.Bag#Slice(i.Info)                           b
	
)