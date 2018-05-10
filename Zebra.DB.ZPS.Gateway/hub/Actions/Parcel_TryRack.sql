/*
	@number = Barcode
	!!! Temperory function, need complete
*/
-- Eason
CREATE PROCEDURE [hub].[Parcel$TryRack](@number tvp)

-- WITH ENCRYPTION
AS BEGIN
	select	isnull(
			(select	case (select cast(Number as bigint) % 2)
					when 1 then  cast(1 as bit)
					else         cast(0 as bit) end
			from	svc.Parcel$ScanOne(@number))
	,		0)  as result
END