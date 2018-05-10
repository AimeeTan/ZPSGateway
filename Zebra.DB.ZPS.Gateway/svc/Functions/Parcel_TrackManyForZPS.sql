--Smile
CREATE FUNCTION [svc].[Parcel$TrackManyForZPS](@numbersInCsv nvarchar(max), @siteID int)
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
		join	core.Matter#Raw()        r on r.Type=m.Parcel and r.ID=n.MatterID 
		cross	apply core.RefNbr#Type() k
		where	(case when n.Type in (k.ClientRef, k.PreCourier) then @siteID else r.PosterID end)=r.PosterID
	)
	, cteMarked as
	(
		select	x.TrackingID,      x.TrackingNbr
		,		ID,		Type,      MatterID, StateID,   Stage,    TalliedOn
		,		UserID, UserAlias, UtcTime,  UtcOffset, UtcPlace, UtcPlaceID
		,		Marker=lead(ID) over (partition by x.SeqID order by Stage)
		from	cteMatter x
		cross	apply core.Activity#Track(x.TrackingID)
	)
	select	ID=TrackingID, TrackingNbr, Stage
	,		UtcTime,       UtcOffset,   UtcPlace
	from	cteMarked where Marker is null
)
