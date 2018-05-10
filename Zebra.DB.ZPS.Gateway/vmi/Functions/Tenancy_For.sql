--Smile
CREATE FUNCTION [vmi].[Tenancy$For](@userID int)
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	Tvp=concat(p.ID, k.Quad, p.PID, k.Quad, p.AID, k.Quad, t.Alias, k.Duad, r.RoleIDs)
	from	tvp.Spr#Const()   k, core.User#Raw() x
	join	core.Party#Raw()  p  on p.ID=x.ID
	join	core.Tenant#Raw() t  on t.ID=p.AID
	cross	apply core.RoleID#Tvp(x.ID) r
	where	x.ID=@userID
)