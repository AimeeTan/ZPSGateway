/*
@slip    = at.Tvp.Duad.Join(ActionID, at.tvp.Trio.join(UtcTime, UtcOffset, UtcPlaceID))
@context = at.Tvp.Triad.Join(MatterID, ETD, ETA)			
*/
-- Aimee, Smile
CREATE PROCEDURE [svc].[Flight$Transit](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);
		
		declare	@actionID I32, @utcStamp tvp;
		select	@actionID=v1,  @utcStamp=v2
		from	tvp.Duad#Of(@slip, default);

		declare	@flightID I64, @etd datetime2(2), @eta datetime2(2)
		select	@flightID=v1
		,		@etd=isnull(nullif(v2, ''), dbo.DT@Empty())
		,		@eta=isnull(nullif(v3, ''), dbo.DT@Empty())
		from	tvp.Triad#Of(@context, default) x

		declare	@spec core.TransitionSpec; insert @spec select t.* 
		from	core.Matter#Tobe(@flightID, @roleID, @actionID) t;
		execute	core.Matter#CascadeBySpecWithStamp @spec=@spec, @userID=@userID, @utcStamp=@utcStamp;
		
		with flightCte as
		(
			select	ETD, ETA 
			from	core.Action#ID() k, tms.Flight#Raw() f 
			where	f.ID=@flightID 
			and		@actionID in (k.CfmFlightDepartureDelayed, k.CfmCustomsHeld)
		)
		update	flightCte set ETD=@etd, ETA=@eta ;
	

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END