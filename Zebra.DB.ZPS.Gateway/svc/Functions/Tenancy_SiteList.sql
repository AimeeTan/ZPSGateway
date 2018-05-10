--Smile
CREATE FUNCTION [svc].[Tenancy$SiteList]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.Alias, TenantID=x.PID, TenantAlias=d.Alias, x.Source, t.UtcPlace, t.UtcOffset
	,		BizUnitID, BizUnit=b.Alias
	from	core.Party#Raw()         x
	join	core.Party#Raw()         d on d.ID=x.PID
	join	core.Tenant#Raw()        t on x.ID=t.ID
	cross	apply acct.Contract#For(d.ID, d.Source) c 
	join	core.Party#Raw()         b on b.ID=c.BizUnitID
	cross	apply core.Party#Type()  k
	where	x.Type=k.TenantSite
)