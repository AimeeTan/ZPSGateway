/*
	@result = Duad<RouteCode, Stage>
*/
--AaronLiu
CREATE PROCEDURE [lc].[Parcel$CheckIn](@number varchar(40), @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@minStage E32,    @maxStage E32;
		select	@minStage=PreMin, @maxStage=PreMax
		from	core.Stage#Boundary();

		declare	@matterID I64;
		select	@matterID=MatterID
		from	core.RefNbr#ScanMulti(@number, @minStage, @maxStage);
		
		declare	@rcvHubID I32,   @userID I32;
		select	@rcvHubID=HubID, @userID=UserID
		from	loc.Tenancy#Of(@tenancy);

		execute	core.Activity#OnceHubAccepted @matterID=@matterID, @userID=@userID;

		update	shpt._Parcel set RcvHubID=@rcvHubID where ID=@matterID;

		declare	@actionID I32=(select HubCheckIn from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@matterID, @actionID=@actionID, @tenancy=@tenancy;

		select	@result=d.Tvp
		from	shpt.Parcel#Deep()  x
		cross	apply tvp.Duad#Make(x.RouteCode, x.Stage) d
		where	x.ID=@matterID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
