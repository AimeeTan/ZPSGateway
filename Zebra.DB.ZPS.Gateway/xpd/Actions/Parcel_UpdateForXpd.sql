/*
@slip    = =Many[Triad<MIC, RefInfoType, RefInfo>]
*/
--Aimee
CREATE PROCEDURE [xpd].[Parcel$UpdateForXpd](@slip tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;

		declare @exeSlip tvp;
		with cteParcel(text) as
		(
			select	[text()]=concat(k.Many, m.MatterID, k.Triad, x.v2, k.Triad, x.v3)
			from	tvp.Triad#Slice(@slip, default, default) x
			cross	apply core.MIC#IdOf(x.v1) m
			join	core.Matter#Raw()         t on t.ID=m.MatterID
			cross	apply core.Stage#ID()     s
			cross	apply tvp.Spr#Const()     k
			where	t.Stage<=s.RouteAssigned
			for		xml path(N'')
		)
		select @exeSlip=Tvp from cteParcel cross apply tvp.Spr#Purify(text, default);
		execute core.RefInfo#Merge @slip=@exeSlip;
	
		-- Upd Parcel.
		with cteParcelCnee as
		(
			select	m.MatterID, ZoneCode=c.v11, t.Source
			from	tvp.Triad#Slice(@slip, default, default) x
			cross	apply core.MIC#IdOf(x.v1) m
			join	core.Matter#Raw()         t on t.ID=m.MatterID
			cross	apply tvp.Dozen#Of(x.v3, default) c
			cross	apply core.Stage#ID()     s
			cross	apply core.RefInfo#Type() r
			where	x.v2=r.CneeInfo and t.Stage<=s.RouteAssigned
		)
		update	p set SvcZone=z.Zone,   POA=f.POA,  ZoneCode=t.ZoneCode
		from	shpt._Parcel p join cteParcelCnee t on t.MatterID=p.ID
		cross	apply tms.ZoneCode#For(t.ZoneCode) c
		cross	apply tms.SvcFacility#For(t.Source, p.SvcClass, c.Zip3) f
		outer	apply tms.SvcZone#For(t.Source, p.SvcClass, f.ImportZip3, c.Zip3) z
		;
END
