--Simile
CREATE FUNCTION [svc].[User$List]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, RoleID, Name, Email
	from	core.User#Raw()           x
	join	core.UserRole#Raw()       u on u.UserID=x.ID
	cross	apply core.Contact#Type() k
	left	join core.Contact#Raw()   c on c.PartyID=x.ID and c.Type=k.Billing
)
