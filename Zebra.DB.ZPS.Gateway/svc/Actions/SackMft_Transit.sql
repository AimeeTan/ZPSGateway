/*
@slip    = at.Tvp.Duad.Join(ActionID, at.tvp.Trio.join(UtcTime, UtcOffset, UtcPlaceID))
@context = ManifestID;
*/
--PeterHo, Smile
CREATE PROCEDURE [svc].[SackMft$Transit](@slip tvp, @context tvp, @tenancy tvp)
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
		
		declare	@actionID I32, @utcStamp tvp;
		select	@actionID=v1,  @utcStamp=v2
		from	tvp.Duad#Of(@slip, default);

		declare	@sackMftID I64=@context;
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from core.Matter#Tobe(@sackMftID, @roleID, @actionID) t

		execute	core.Matter#CascadeBySpecWithStamp @spec=@spec, @userID=@userID, @utcStamp=@utcStamp;
		--execute	core.RefStamp#MergeBySpec @spec=@spec, @utcStamp=@utcStamp;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END