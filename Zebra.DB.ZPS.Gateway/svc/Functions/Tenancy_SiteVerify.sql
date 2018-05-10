--Aimee, Smile, Irene
CREATE FUNCTION [svc].[Tenancy$SiteVerify](@siteID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	SiteID=isnull(ID, 0)
	from	core.Party#Type() k, core.Party#Raw() x
	where	x.Type=k.TenantSite and x.ID=@siteID
)
