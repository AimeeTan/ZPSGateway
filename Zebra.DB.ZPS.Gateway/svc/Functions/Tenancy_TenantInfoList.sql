--Smile
CREATE FUNCTION [svc].[Tenancy$TenantInfoList]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.Alias, x.Source, UtcPlace, UtcOffset, Contact=c.Tvp
	,		BizUnitID, BizUnit=b.Alias, BillingCycle, DutyTerms, NonDutyTerms
	,		EffectiveOn=isnull(EffectiveOn, ''), ExpiredOn=isnull(ExpiredOn, '')
	from	core.Party#Raw()           x 
	join	core.Tenant#Raw()          p on p.ID=x.ID
	cross	apply acct.Contract#For(p.ID, p.Source) r
	join	core.Party#Raw()           b on b.ID=r.BizUnitID
	cross	apply core.Contact#Type()  k
	outer	apply core.Contact#TvpFor( x.ID, k.Billing) c 
	cross	apply core.Party#Type()    t
	where	x.ID>0 and x.Type=t.Tenant
)