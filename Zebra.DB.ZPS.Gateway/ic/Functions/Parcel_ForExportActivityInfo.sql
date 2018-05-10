--Aimee Tan, Sean Rao
CREATE FUNCTION [ic].[Parcel$ForExportActivityInfo]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, Stage,    x.Source, RcvHubID, RcvHubAlias, RouteID,  RouteCode
	,		SiteAlias,      LastMilerAlias,     PostedOn,    StatedOn, RefNbrs
	,		Weight,			Length,				Height,		 Width
	,		TenantID=p.PID, Activities=e.Tvp
	from	shpt.Parcel#Deep() x
	join	core.Party#Raw()   p on p.ID=x.SiteID
	outer	apply
	(
		select	[text()]=concat(k.Many, Stage, k.Quad, TalliedOn, k.Quad, t.UtcOffset, k.Quad, p.UtcOffset)
		from	core.Activity#Raw()    a
		left	join core.Tenant#Raw() t on t.ID=x.RcvHubID
		left	join core.Port#Raw()   p on p.Code=x.POA
		cross	apply core.Stage#Of(a.StateID) s
		cross	apply tvp.Spr#Const()  k
		where	a.MatterID=x.ID for xml path(N'')
	) z (text)
	cross	apply tvp.Spr#Purify(z.text, default) e
)
