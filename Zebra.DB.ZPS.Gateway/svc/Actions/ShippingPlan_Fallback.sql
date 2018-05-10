/*
@slip  = Duad.Join(parcelID, svcTypeID)
*/
--Eva, PeterHo, Daxia
CREATE PROCEDURE [svc].[ShippingPlan$Fallback](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@altSvcType I32=78010001; -- TODO:
		declare	@poa char(3), @routeID I32,     @lastMilerID I32;
		select	@poa=POA,     @routeID=RouteID, @lastMilerID=CourierID
		from	tms.SvcRoute#For(@altSvcType, '')

		declare	@parcelID I64=(select v1 from tvp.Duad#Of(@slip, default));
		update	shpt._Parcel
		set		SvcType=@altSvcType, POA=@poa, RouteID=@routeID, LastMilerID=@lastMilerID
		where	ID=@parcelID;

		declare	@userID I32,    @roleID I32,    @actionID I32;
		select	@userID=UserID, @roleID=RoleID, @actionID=FallbackShipping
		from	loc.Tenancy#Of(@tenancy), core.Action#ID();

		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from shpt.Parcel#Tobe(@parcelID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
