--Smile
CREATE FUNCTION [svc].[Tenancy$UserInfoList]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.Alias, x.Source, Name, Email, TenantID=a.ID, TenantAlias=a.Alias
	,		SiteID=iif(x.AID=x.PID, 0, p.ID), SiteAlias=iif(x.AID=x.PID, N'', p.Alias)
	,		BizUnitID, BizUnit=d.Alias
	from	core.Party#Raw()          x 
	join	core.Party#Raw()          p on p.ID=x.PID
	join	core.Party#Raw()          a on a.ID=x.AID
	cross	apply acct.Contract#For(a.ID, a.Source) o
	join	core.Party#Raw()          d on d.ID=o.BizUnitID
	cross	apply core.Party#Type()   k
	cross	apply core.Contact#Type() t
	left	join core.Contact#Raw()   c on c.PartyID=x.ID and c.Type=t.Billing
	where	x.Type=k.Operator
)