--PeterHo
CREATE FUNCTION [svc].[Parcel$Track](@parcelID bigint)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with cteTvp(text) as
	(
		select	[text()]=concat(k.Many
		,		ID,       k.Tuplet, Stage,     k.Tuplet
		,		UserID,   k.Tuplet, UserAlias, k.Tuplet
		,		UtcPlace, k.Tuplet, UtcTime,   k.Tuplet, UtcOffset)
		from	core.Activity#Track(@parcelID)
		,		tvp.Spr#Const() k for xml path(N'')
	)
	select	Tracks=Tvp, l.CourierCode, CourierNbr=isnull(c.Number, N'')
	from	cteTvp cross apply tvp.Spr#Purify(text, default)
	join	shpt.Parcel#Raw() p on p.ID=@parcelID
	join	tms.Courier#Raw() l on l.ID=p.LastMilerID
--	join	tms.Route#Deep()  r on r.ID=p.RouteID -- dropped on 2017-08-19
	outer	apply
	(
		select	Number from	core.RefNbr#Raw() n
		cross	apply  core.RefNbr#Type()     t
		where	n.MatterID=@parcelID and n.Type=t.PostCourier
	) c
)
