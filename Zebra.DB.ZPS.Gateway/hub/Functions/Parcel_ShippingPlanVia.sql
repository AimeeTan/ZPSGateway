-- Eva
CREATE FUNCTION [hub].[Parcel$ShippingPlanVia](@number varchar(40))
RETURNS TABLE
--, ENCRYPTION
WITH SCHEMABINDING
AS RETURN 
(
	select	ID=x.MatterID, x.Number, ShippingPlan=i.Info
	from	core.RefNbr#ScanOne(@number, default, default)        x
	cross	apply core.RefInfo#Type()                             t
	cross	apply core.RefInfo#Of(x.MatterID, t.ShippingPlanInfo) i
	cross	apply core.Matter#Type()                              mt
	where	x.Type=mt.Parcel
)