-- Eason
CREATE FUNCTION [svc].[Parcel$ForBrokerage]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, m.PID, AID, m.Source, Type, LockCnt, Stage, m.StateID, StatedOn, PostedOn
	,		RcvHubID,  RcvHubAlias=c.Alias
	,		RouteID,   RouteCode, BrokerID, CourierID       , ClrMethodID
	,		POA,       SvcType,   SvcZone,  SvcClass, Weight, Length, Width, Height
	,		RefNbrs,   RefInfos=i.RefInfos
	,		Endorsement=e.Tvp
	from	shpt.Parcel#Raw()            x
	join	core.Matter#Raw()            m on m.ID=x.ID
	join	tms.Route#Raw()              r on r.ID=x.RouteID
	join	core.Tenant#Raw()			 c on c.ID=x.RcvHubID
	cross	apply core.RefInfo#Tvp(x.ID) i
	cross	apply core.RefInfo#Type()    t
	cross	apply core.RefNbr#Tvp(x.ID)  rn
	cross	apply
	(
		select	Info=i.v2
		from	tvp.Duad#Slice(i.RefInfos, default, default)  i
		where	i.v1=t.BrokerageInfo
	) ri	
	cross	apply
	(
		select	[text()]=concat(k.Many, b.SkuID, k.Triad, mt.v3, k.Triad, e.v2)
		from	tvp.Spr#Const() k, tvp.Mucho#Slice(ri.Info) m
		cross	apply tvp.Triad#Of(m.Piece, default)        mt
		join	invt.SkuBrokerage#Raw()                     b
		on		b.SkuID=cast(mt.v1 as int) and b.BrokerID=r.BrokerID and b.ClrMethodID=r.ClrMethodID
		cross	apply tvp.Pair#Of(b.Endorsement)			e
		for	xml path(N'')
	) z (text)
	cross	apply tvp.Spr#Purify(z.text, default) e
)