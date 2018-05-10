--Sam
CREATE	FUNCTION [svc].[SackMft$Export]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, p.RefNbrs, p.RefInfos,  p.Weight, p.RouteID, p.PostedOn
	from	shpt.SackMft#Raw()  x
	join    shpt.Parcel#Deep()  p on p.PID = x.ID
)



