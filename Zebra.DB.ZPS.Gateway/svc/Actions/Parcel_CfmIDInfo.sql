/*
	@slip = Many[Triad<MatterID, RefInfoType, IDInfo>]
*/
-- AaronLiu
CREATE PROCEDURE [svc].[Parcel$CfmIDInfo](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		execute	core.RefInfo#Merge @slip=@slip;	

		declare	@idsInCsv tvp;
		with	cte(text) as
		(
			select	[text()]=concat(N',', x.v1)
			from	tvp.Triad#Slice(@slip, default, default) x
			for		xml path(N'')
		)
		select	@idsInCsv=Tvp from cte cross apply tvp.Spr#Purify(text, 1);
		declare	@actionID I32=(select ConfirmIDInfo from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@idsInCsv, @actionID=@actionID, @tenancy=@tenancy;
	
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END