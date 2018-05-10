/*
@slip = Comma<AppointmentID>
*/
--AaronLiu
CREATE PROCEDURE [svc].[Appointment$StartOff](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@actionID  E32=(select DriverStartOff=17276 from core.Action#ID());	--HACK

		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from core.Matter#TobeVia(@slip, @roleID, @actionID) t
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;
			
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH 
END