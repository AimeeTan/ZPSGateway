/*
	@slip = Comma<SackLoadID>
*/
-- AaronLiu
CREATE PROCEDURE [hub].[SackLoad$Transload](@slip tvp, @tenancy tvp)
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

		--	Transit SackLoad and Cascading:
		declare	@actionID E32=(select CfmTransload from core.Action#ID());
		declare	@spec core.TransitionSpec
		insert	@spec select t.*
		from	tvp.I64#Slice(@slip)			x
		cross	apply core.Matter#ANodeDn(x.ID) m
		cross	apply core.Matter#Tobe(m.ID, @roleID, @actionID) t;

		-- TODO: Ask Peter Add BeAffected
		execute	core.Matter#CascadeAllBySpec @spec=@spec, @userID=@userID;
			
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
