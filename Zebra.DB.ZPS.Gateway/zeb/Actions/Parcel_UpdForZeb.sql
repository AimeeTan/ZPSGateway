/*
	@slip = Duad.Join(parcelID, svcTypeID)
*/
-- AaronLiu
CREATE PROCEDURE [zeb].[Parcel$UpdForZeb](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@siteID I32,    @userID I32;
		select	@siteID=SiteID, @userID=UserID
		from	loc.Tenancy#Of(@tenancy);

		declare	@parcelID I64, @svcTypeID I32;
		select	@parcelID =v1, @svcTypeID =v2
		from	tvp.Duad#Of(@slip, default);

		declare	@poa char(3), @routeID I32,     @lastMilerID I32;
		select	@poa=POA,     @routeID=RouteID, @lastMilerID=CourierID
		from	tms.SvcType#For(@svcTypeID, @siteID)		x
		cross	apply tms.SvcRoute#For(x.ID, x.FallbackPOA) s;

		update	shpt._Parcel
		set		SvcType=@svcTypeID, POA=@poa, RouteID=@routeID, LastMilerID=@lastMilerID
		where	ID=@parcelID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
