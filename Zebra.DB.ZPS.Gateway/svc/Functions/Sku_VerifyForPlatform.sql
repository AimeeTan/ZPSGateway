/*
@skus = Triad[Alias, Mucho<skus>, SvcType]
*/
--Smile
CREATE FUNCTION [svc].[Sku$VerifyForPlatform](@userID int, @skus nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID=isnull(cast(d.SkuID as bigint), 0), c.SkuNbr, SvcType=isnull(cast(x.v3 as int), 0)
	from	tvp.Triad#Slice(@skus, default, default)	x	
	cross	apply tvp.Mucho#Slice(x.v2)					m
	cross	apply loc.SkuNbr#Cast(m.Piece)				c
	join	core.Party#Raw()							n on n.ID=@userID
	left	join core.Party#Raw()						p on p.Alias=x.v1 and p.Source=n.Source
	left	join invt.Sku#Raw()							t on t.TenantID=p.PID and t.SkuNbr=c.SkuNbr
	cross	apply tms.SvcType#For(x.v3, p.ID)			s
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
