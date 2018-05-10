--Daxia
CREATE FUNCTION [svc].[User$ContactName](@userID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, Name=isnull(Name, N''),  Handler=concat('(', x.ID, ') ', Name)
	from	core.User#Raw()           x 
	cross	apply core.Contact#Type() k
	left	join core.Contact#Raw()   c on c.PartyID=x.ID and c.Type=k.Billing
	where	x.ID=@userID
)
