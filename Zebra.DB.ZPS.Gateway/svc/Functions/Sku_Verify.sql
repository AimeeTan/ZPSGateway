--PeterHo, Smile
CREATE FUNCTION [svc].[Sku$Verify](@siteID int, @svcType int, @skuNbrs nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	
	select	ID=isnull(cast(d.SkuID as bigint), 0), c.SkuNbr
	from	tvp.Many#Slice(@skuNbrs)       x
	cross	apply loc.SkuNbr#Cast(x.Piece) c
	join	core.Party#Raw()               p on p.ID=@siteID
	left	join invt.Sku#Raw()            t on t.TenantID=p.PID and t.SkuNbr=c.SkuNbr
	cross	apply tms.SvcType#For(@svcType, @siteID)    s
	cross	apply tms.SvcRoute#For(s.ID, s.FallbackPOA) r
	join	tms.Route#Raw()                             a on a.ID=r.RouteID
	outer	apply
	(
		select	top(1) SkuID from invt.SkuBrokerage#Raw()
		where	SkuID=t.ID 
		and		ClrMethodID=a.ClrMethodID
		and		BrokerID=a.BrokerID
	) d
)
