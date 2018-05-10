-- AaronLiu
CREATE FUNCTION [zeb].[Parcel$RePacked](@parcelID I64)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID
	from	shpt.Parcel#Base()
	where	AID=@parcelID
)