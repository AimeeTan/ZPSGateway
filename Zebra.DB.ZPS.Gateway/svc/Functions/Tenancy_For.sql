--Eva, PeterHo
CREATE FUNCTION [svc].[Tenancy$For](@userID int)
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	Tvp=concat(p.ID, k.Quad, p.PID, k.Quad, p.AID, k.Quad, x.Alias, k.Duad, r.RoleIDs)
	from	tvp.Spr#Const()  k, core.User#Raw() x
	join	core.Party#Raw() p  on p.ID=x.ID
	cross	apply core.RoleID#Tvp(x.ID) r
	where	x.ID=@userID
)