﻿--Daxia
CREATE PROCEDURE [svc].[Parcel$RequeueBrkgApi](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@actionID I32=(select RequeueBrkgApi from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@slip, @actionID=@actionID, @tenancy=@tenancy;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
