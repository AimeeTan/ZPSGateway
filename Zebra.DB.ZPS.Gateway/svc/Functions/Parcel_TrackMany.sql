--PeterHo
CREATE FUNCTION [svc].[Parcel$TrackMany](@numbersInCsv nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=TrackingID, TrackingNbr, Stage
	,		UtcTime,       UtcOffset,   UtcPlace
	from	core.Activity#TrackMany(@numbersInCsv)
)
