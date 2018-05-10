--PeterHo
CREATE FUNCTION [svc].[Parcel$TrackOne](@trackingNbr varchar(40))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	Tracks, CourierCode, CourierNbr
	from	core.RefNbr#ScanOne(@trackingNbr, default, default) x
	cross	apply svc.Parcel$Track(x.MatterID) a

/*
	select	ID, a.Stage, UserID,  UserAlias
	,		UtcPlace,    UtcTime, UtcOffset
	from	core.RefNbr#ScanOne(@trackingNbr, default, default) x
	cross	apply svc.Parcel$Track(x.MatterID) a
*/
)
