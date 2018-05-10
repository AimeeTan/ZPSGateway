-- Smile
CREATE FUNCTION [co].[Tenancy$UserList](@tenantID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	with	cteSubType as
	(
		select	t.ID, t.PID, Alias, t.Type, Name, Email
		from	svc.Tenancy$Subtype(@tenantID,default, default) t
		cross	apply core.Contact#Type() c
		left	join  core.Contact#Raw()  o on o.PartyID=t.ID and o.Type=c.Billing
	)
	select	x.ID, x.Alias, Name, Email, SiteID=isnull(p.ID, 0), SiteAlias=isnull(p.Alias, N'')
	from	cteSubType               x
	cross	apply core.Party#Type()  k
	left	join  core.Party#Raw()   p on p.ID=x.PID and p.Type=k.TenantSite
	where	x.Type=k.Operator and x.ID>0
)
