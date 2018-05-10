--Smile
CREATE	FUNCTION [svc].[CustomerCode$Vefity](@userID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=isnull(p.ID,0), p.Alias
	from	core.Party#Raw()        x
	cross	apply core.Party#Type() k
	join	core.Party#Raw()        p on p.Source=x.Source and p.Type=k.TenantSite
	where	x.ID=@userID
)
