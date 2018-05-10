/*
	@slip = SackID
*/
-- AaronLiu
CREATE PROCEDURE [hub].[Sack$Void](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@sackActionID	E32=(select VoidSack			 from core.Action#ID());
		declare	@parcelActionID E32=(select RemoveParcelFromSack from core.Action#ID());
		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from core.Matter#TobeVia(@slip, @roleID, @sackActionID) t;
		insert	@spec select t.* from core.Matter#Raw() m
		cross	apply shpt.Parcel#Tobe(m.ID, @roleID, @parcelActionID) t
		where	m.PID=cast(@slip as bigint);

		-- 1.1	Link Parcel's PID to Original SackMft
		with cteParcel as
		(
			select	p.ID, p.PID, SackMftID=x.PID
			from	shpt.Sack#Base()  x
			join	core.Matter#Raw() p on p.PID=x.ID
			where	x.ID=cast(@slip as bigint)
		)
		update cteParcel set PID=SackMftID;

		-- 1.2	Change Sack's PID to 0
		update	core._Matter set PID=0, AID=0 where ID=cast(@slip as bigint);

		-- 2.0	Transit Sack&Parcel
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END