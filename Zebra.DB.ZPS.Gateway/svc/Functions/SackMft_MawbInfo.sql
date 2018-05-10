--	Smile
CREATE	FUNCTION [svc].[SackMft$MawbInfo]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	SELECT	ID, MawbNbr, POA, p.UtcOffset, p.UtcPlaceID
	FROM 	shpt.SackMft#Base()   x
	join	core.Port#Raw()       p on p.Code=x.POA
	cross	apply core.Stage#ID() k
	where	x.Stage=k.Arrived
)
