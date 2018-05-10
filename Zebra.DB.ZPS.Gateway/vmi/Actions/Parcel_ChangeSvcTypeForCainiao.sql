/*
@slip    = Tuplet[TrackingNbr, SvcType,  CourierCode, PostCourierNbr, LabelInfo]
@result  = Count(ChangedParcel)
*/
--Smile
CREATE PROCEDURE [vmi].[Parcel$ChangeSvcTypeForCainiao](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@siteID I32,    @userID I32,    @roleID I32;
		select	@siteID=SiteID, @userID=UserID, @roleID=x.RoleID
		from	loc.Tenancy#Of(@tenancy) x;

		declare	@ids I64Array;
		with cteParcel as
		(
			select	p.ID, p.SvcType, p.RouteID, LastMilerID
			,		NewSvcType=t.ID, NewRouteID=o.RouteID, NewLastMilerID=l.CourierID
			from	tvp.Tuplet#Slice(@slip, default, default) x
			cross	apply tms.Courier#IdOfAlias(x.v3)         l
			cross	apply core.RefNbr#ScanOne(x.v1, default, default) m
			join	shpt.Parcel#Raw()                   p on p.ID=m.MatterID
			cross	apply tms.SvcType#Major(p.SvcType)  d
			cross	apply tms.SvcType#Major(x.v2)       r
			cross	apply tms.SvcType#For(cast(x.v2 as int), @siteID) t
			cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)       o
			where	d.Major in (78400000, 78410000, 78420000, 78430000)
			and		r.Major in (78400000, 78410000, 78420000, 78430000)
		)
		update	cteParcel set SvcType=NewSvcType, RouteID=NewRouteID, LastMilerID=NewLastMilerID
		output	inserted.ID into @ids;

		declare	@exeNbr tvp;
		with exeNbr(text) as
		(
			select	[text()]=concat(k.Many, m.MatterID, k.Triad, t.PostCourier, k.Triad, x.v4)
			from	tvp.Tuplet#Slice(@slip, default, default) x
			cross	apply core.RefNbr#ScanOne(x.v1, default, default) m
			cross	apply tvp.Spr#Const()                                     k
			cross	apply core.RefNbr#Type()                                  t
			where	m.MatterID in (select ID from @ids)
			for xml path(N'')
		)
		select	@exeNbr=Tvp from exeNbr cross apply tvp.Spr#Purify(text, default)  	
		execute	core.RefNbr#Merge @slip=@exeNbr;

		declare	@exeInfo tvp;
		with exeInfo(text) as
		(
			select	[text()]=concat(k.Many, m.MatterID, k.Triad, t.ShippingLabelInfo, k.Triad, x.v5)
			from	tvp.Tuplet#Slice(@slip, default, default) x
			cross	apply core.RefNbr#ScanOne(x.v1, default, default) m
			cross	apply tvp.Spr#Const()                                     k
			cross	apply core.RefInfo#Type()                                 t
			where	m.MatterID in (select ID from @ids)
			for xml path(N'')
		)
		select	@exeInfo=Tvp from exeInfo cross apply tvp.Spr#Purify(text, default)  	
		execute	core.RefInfo#Merge @slip=@exeInfo;

		declare	@spec core.TransitionSpec;
		declare	@actionID I32=(select ShipperRelease from core.Action#ID());
	
		insert	@spec select t.* from @ids x 
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		select	@result=(select count(*) from @spec);
		
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
