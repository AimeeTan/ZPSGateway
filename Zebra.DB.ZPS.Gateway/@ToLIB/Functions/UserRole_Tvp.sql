-- Smile
CREATE FUNCTION [core].[UserRole#Tvp](@userID int)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with cteTvp(text) as
	(
		select	[text()]=concat( N',', x.RoleID)
		from	core.UserRole#Raw() x
		where	x.UserID=@userID
		for	xml path(N'')
	)
	select	Tvp from cteTvp cross apply tvp.Spr#Purify(text, 1)
)