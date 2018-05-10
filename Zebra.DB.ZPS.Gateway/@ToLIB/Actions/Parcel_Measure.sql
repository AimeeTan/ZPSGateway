-- AaronLiu
CREATE PROCEDURE [shpt].[Parcel#Measure](@matterID I64, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@actionID I32,		@exeActionID I32;
		select	@actionID=ActionID, @exeActionID=ExeActionID, @tenancy=TobeTenancy
		from	core.Measure#Todo(@matterID, @tenancy)

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare @spec core.TransitionSpec;
		insert	@spec select t.* from shpt.Parcel#TobeVia(@matterID, @roleID, @actionID) t;

		declare	@exeSpec core.TransitionSpec;
		insert	@exeSpec select t.* from shpt.Parcel#TobeVia(@matterID, @roleID, @exeActionID) t;

		with	cteMatter as
		(
			select	m.ID, RejoinID, NewRejoinID=x.ToStateID
			from	core.Matter#Raw() m
			join	@spec			  x on x.MatterID=m.ID
			join	@exeSpec		  v on x.MatterID=v.MatterID
		)
		update	cteMatter set RejoinID=NewRejoinID;

		execute	core.Matter#TransitBySpec @spec=@exeSpec, @userID=@userID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
