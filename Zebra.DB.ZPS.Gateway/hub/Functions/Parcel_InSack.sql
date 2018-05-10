-- AaronLiu
CREATE	FUNCTION [hub].[Parcel$InSack](@sackID I64)
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	x.ID, x.Weight, x.RefNbrs
	from	shpt.Parcel#Deep() x
	where	x.PID=@sackID
)