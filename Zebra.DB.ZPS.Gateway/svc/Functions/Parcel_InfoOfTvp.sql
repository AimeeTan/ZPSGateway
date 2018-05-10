--Aimee
CREATE FUNCTION [shpt].[Parcel$InfoOfTvp](@parcelID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(

	with cte(text) as
	(
		select	[text()]=concat
		(
			k.Many,   p.ID,
			k.Tuplet, b.BarcodeNbr,
			k.Tuplet, p.SvcType,
			k.Tuplet, p.Weight,
			k.Tuplet, p.Length,
			k.Tuplet, p.Width,
			k.Tuplet, p.Height,
			k.Tuplet, o.Info,
			k.Tuplet, s.ClassCode
		)
		from	shpt.Parcel#Raw() p
		cross	apply tvp.Spr#Const() k
	)
	with cte(text) as
	(
		select	[text()]=concat
		(	
			k.Many,   p.ID,
			k.Tuplet, b.BarcodeNbr,
			k.Tuplet, p.SvcType,
			k.Tuplet, p.Weight,
			k.Tuplet, p.Length,
			k.Tuplet, p.Width,
			k.Tuplet, p.Height,
			k.Tuplet, o.Info,
			k.Tuplet, s.ClassCode
		)
		from	tvp.Spr#Const() k, shpt.Parcel#Raw() p 
		join	tms.SvcClass#Raw()              s on s.ID=p.SvcClass 
		cross	apply core.RefNbr#Type()                        t
		cross	apply core.RefNbr#Of(p.ID,  t.PostCourier)      r
		cross	apply core.RefInfo#Type()                       i
		cross	apply core.RefInfo#Of(p.ID, i.CneeInfo)         o
		cross	apply tms.BarcodeNbr#Make(p.ZoneCode, r.Number) b
		where	p.ID=@parcelID
		for xml path(N'')
	)
	select	ParcelInfo=Tvp from cte cross apply tvp.Spr#Purify(text, default);
)