﻿/*
	@slip = Comma<ParcelID>
*/
-- AaronLiu
CREATE PROCEDURE [api].[Parcel$CfmDoorDeliverdForTC](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

--		declare	@actionID I32=(select CfmDoorDelivered from core.Action#ID());
		declare	@actionID I32=19990;
		execute	svc.Parcel$Transit @idsInCsv=@slip, @actionID=@actionID, @tenancy=@tenancy;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END