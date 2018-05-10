-- Eva, AaronLiu
CREATE FUNCTION [zeb].[Parcel$ViaBarcode](@barcodes tvp)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	with cte(text) as
	(
		select	[text()]=concat(N',', MatterID)
		from	loc.RefNbr#Slice(@barcodes) x
		cross	apply core.RefNbr#Type()    t
		cross	apply core.RefNbr#ScanOne(x.Number, default, default) m
		where	m.Type in (t.ClientRef, t.PreCourier)
		for		xml path(N'')
	)
	select IDs=Tvp from cte cross apply tvp.Spr#Purify(text, 1)
)
/*
	with cte(text) as
	(
		select	[text()]=concat(N',', MatterID)
		from	loc.RefNbr#Slice(@barcodes) x
		join	core.RefNbr#Raw()           n on n.Number=x.Number
		cross	apply core.RefNbr#Type()    t
		where	Type in (t.ClientRef, t.PreCourier)
		for xml path(N'')
	)
	select IDs=Tvp from cte cross apply tvp.Spr#Purify(text, 1)
*/