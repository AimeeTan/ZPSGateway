/*
@slip    => GoodsInfos.Over(at.Tvp.Many.Join)
@context => MatterID
*/
--PeterHo
CREATE PROCEDURE [svc].[Parcel$Verify](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@refType  E8=(select VerifiedInfo from core.RefInfo#Type());
		declare	@exeSlip tvp=(select Tvp from tvp.Triad#Make(@context, @refType, @slip));
		execute	core.RefInfo#Merge @slip=@exeSlip;

		declare	@matterID  I64=@context;
		declare	@actionID  I32=(select HubVerifyWithTappingGreen from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@context, @actionID=@actionID, @tenancy=@tenancy;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
