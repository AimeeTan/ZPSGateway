--Smile
CREATE FUNCTION [svc].[Tenancy$SiteInfoList]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.Alias, x.Source, TenantID=x.PID, TenantAlias=d.Alias
	,		UtcPlace, UtcOffset, Shipping=s.Tvp, Returning=r.Tvp
	from	core.Party#Raw()           x 
	join	core.Party#Raw()           d on d.ID=x.PID
	join	core.Tenant#Raw()          t on x.ID=t.ID
	cross	apply core.Contact#Type()  k
	outer	apply core.Contact#TvpFor(x.ID, k.Shipping)  s
	outer	apply core.Contact#TvpFor(x.ID, k.Returning) r 
	cross	apply core.Party#Type()    p
	where	x.Type=p.TenantSite and x.ID>0
)