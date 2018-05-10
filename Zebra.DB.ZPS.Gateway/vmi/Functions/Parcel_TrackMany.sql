--Smile
CREATE FUNCTION [vmi].[Parcel$TrackMany](@numbersInCsv nvarchar(max), @siteID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
		with cteMatter as
	(
		select	SeqID=row_number() over (order by (select null))
		,		TrackingID =n.MatterID
		,		TrackingNbr=n.Number
		from	loc.RefNbr#Slice(@numbersInCsv)                       x
		cross	apply core.RefNbr#ScanOne(x.Number, default, default) n
		cross	apply core.Matter#Type() m 
		cross	apply core.Source#ID()   s
		join	core.Matter#Raw()        r on r.Type=m.Parcel and r.ID=n.MatterID and r.Source=s.eVMI
		cross	apply core.RefNbr#Type() k
		where	r.PosterID=r.PosterID
	)
	, cteMarked as
	(
		select	x.TrackingID,      x.TrackingNbr
		,		ID,		Type,      MatterID, StateID,   Stage,    TalliedOn
		,		UserID, UserAlias, UtcTime,  UtcOffset, UtcPlace, UtcPlaceID
		from	cteMatter x
		cross	apply core.Activity#Track(x.TrackingID)
	)
	select	ID=TrackingID, TrackingNbr, Stage
	,		UtcTime,       UtcOffset,   UtcPlace
	from	cteMarked
)
