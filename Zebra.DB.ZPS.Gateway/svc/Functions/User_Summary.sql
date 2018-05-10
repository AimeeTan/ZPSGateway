--Smile
CREATE FUNCTION [svc].[User$Summary]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID, Alias, RoleTvps=r.Tvp, Name, Email
	from	core.User#Raw()           x
	cross	apply core.Contact#Type() k
	left	join core.Contact#Raw()   c on c.PartyID=x.ID and c.Type=k.Billing
	cross	apply core.UserRole#Tvp(x.ID) r 
)
