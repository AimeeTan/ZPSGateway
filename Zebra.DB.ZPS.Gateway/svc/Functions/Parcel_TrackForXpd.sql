-- Aimee
CREATE FUNCTION [svc].[Parcel$TrackForXpd](@numbersInCsv nvarchar(max), @siteID int)
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	Tracks, CourierCode, CourierNbr, TrackingNbr=x.Number
	from	core.RefNbr#MatchMulti(@numbersInCsv, default, default) x
	join	core.Matter#Raw() p on p.ID=x.MatterID
	cross	apply svc.Parcel$Track(p.ID)
	where	p.PosterID=@siteID
)