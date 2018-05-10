/*
@slip    = Mucho[Triad<SkuID, CmdyInfo, LineInfo>]
@context = MatterID
*/
--Aimee
CREATE PROCEDURE [svc].[Parcel$Classified](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@exeSlip tvp=
		(
			select	Tvp   from core.RefInfo#Type() k
			cross	apply tvp.Triad#Make(@context, k.BrokerageInfo, @slip)
		);
		execute	core.RefInfo#Merge @slip=@exeSlip;

		declare	@actionID I32=(select DetermineCmdy from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@context, @actionID=@actionID, @tenancy=@tenancy;
	
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END