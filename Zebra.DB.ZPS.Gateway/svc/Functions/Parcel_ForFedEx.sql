--Aimee
CREATE FUNCTION [svc].[Parcel$ForFedEx](@parcelIdInCsv nvarchar(max))
RETURNS TABLE 
--WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	with cte as
	(
		select	f.POA, f.FacilityInfo, f.ShprInfo
		from	tvp.I64#Slice(@parcelIdInCsv) x
		join	shpt.Parcel#Base() p on p.ID=x.ID
		cross	apply tms.SvcFacility#For(p.Source, p.SvcClass, left(p.ZoneCode, 3)) f
		group	by f.POA, f.FacilityInfo, f.ShprInfo
	)
	select	c.POA, c.FacilityInfo, c.ShprInfo, ParcelInfo=stuff(z.Detail, 1, 3, N'')
	from	cte c
	cross apply
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
		from	tvp.I64#Slice(@parcelIdInCsv) x
		cross	apply tvp.Spr#Const()         k
		join	shpt.Parcel#Raw()             p on p.ID=x.ID
		join	tms.SvcClass#Raw()            s on s.ID=p.SvcClass 
		cross	apply core.RefNbr#Type()                        t
		cross	apply core.RefNbr#Of(p.ID,  t.PostCourier)      r
		cross	apply core.RefInfo#Type()                       i
		cross	apply core.RefInfo#Of(p.ID, i.CneeInfo)         o
		cross	apply tms.BarcodeNbr#Make(p.ZoneCode, r.Number) b
		where	c.POA=p.POA
		for		xml path('')
	) z (Detail)
)