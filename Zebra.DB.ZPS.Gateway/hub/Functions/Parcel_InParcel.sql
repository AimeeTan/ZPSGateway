-- AaronLiu
CREATE	FUNCTION [hub].[Parcel$InParcel](@parcelID I64)
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID, RefNbrs
	from	shpt.Parcel#Deep()
	where	PID=@parcelID
)