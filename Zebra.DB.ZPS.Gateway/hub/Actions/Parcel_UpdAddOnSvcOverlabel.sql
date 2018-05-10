/*
	@slip tvp = ParcelID
*/
-- Aimee
create PROCEDURE [hub].[Parcel$UpdAddOnSvcOverlabel](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32; select @userID=UserID from	loc.Tenancy#Of(@tenancy);
		update	o set o.OperatorID=@userID, o.EndedOn=getutcdate() 
		from	core.AddOnSvc#Raw()         o
		cross	apply core.AddOnSvc#Type()  k
		where	o.MatterID=cast(@slip as bigint) and o.Type=/*k.Overlabel*/106

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END