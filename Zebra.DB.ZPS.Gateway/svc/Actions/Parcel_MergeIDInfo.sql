/*
@slip    = Many[Triad<MatterID, RefInfoType, RefInfo>]
@context = MatterID
*/
--Daxia
CREATE PROCEDURE [svc].[Parcel$MergeIDInfo](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		execute	core.RefInfo#Merge @slip=@slip;	

		declare	@actionID I32=(select UpdateIDPicture from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@context, @actionID=@actionID, @tenancy=@tenancy;
	
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END