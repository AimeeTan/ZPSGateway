/*
@slip = Comma<AppointmentID>
*/
--AaronLiu
CREATE PROCEDURE [svc].[Appointment$CallOff](@slip tvp, @tenancy tvp)
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

		declare	@actionID  E32=(select CallOffDriver=17275 from core.Action#ID())	--HACK
		,		@partyRole E32=(select Ramper			   from core.Party#Role());

		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from core.Matter#TobeVia(@slip, @roleID, @actionID) t
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		execute	core.RefParty#MergeVia @idsInCsv=@slip, @partyRole=@partyRole, @partyID=0;
			
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH 
END