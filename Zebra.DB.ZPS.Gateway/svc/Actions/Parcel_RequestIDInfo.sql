/*
	@slip = Comma<ParcelID>
*/
-- AaronLiu
CREATE PROCEDURE [svc].[Parcel$RequestIDInfo](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@actionID	 I32=(select ConfirmIDInfo	  from core.Action#ID())
		,		@exeActionID I32=(select RequestIDPicture from core.Action#ID());

		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from shpt.Parcel#TobeVia(@slip, @roleID, @actionID) t;

		declare	@exeSpec core.TransitionSpec;
		insert	@exeSpec select t.* from shpt.Parcel#TobeVia(@slip, @roleID, @exeActionID) t;

		execute	core.Matter#TransitBySpec @spec=@exeSpec, @userID=@userID, @beAffected=1;

		with	cteMatter as
		(
			select	m.ID, RejoinID, NewRejoinID=x.ToStateID
			from	core._Matter m
			join	@spec        x on x.MatterID=m.ID
			join	@exeSpec     v on x.MatterID=v.MatterID
		)
		update	cteMatter set RejoinID=NewRejoinID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END