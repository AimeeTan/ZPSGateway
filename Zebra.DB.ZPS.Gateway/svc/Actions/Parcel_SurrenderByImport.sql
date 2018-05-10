/*
@slip	=Many[Duad<MIC, LastMilerTrackingNbr>]
@result	=Many[Triad<MatterID, 9, LastMilerTrackingNbr>] // todo: may refine later
*/
--Eva
CREATE PROCEDURE [svc].[Parcel$SurrenderByImport](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@minStage E32,       @maxStage E32;
		select	@minStage=Outgated, @maxStage=Surrendered
		from	core.Stage#ID();

		declare	@idsInCsv tvp, @refNbrSlip tvp;
		with	cte(text) as
		(
			select	[text()]=concat(k.Many, i.MatterID, k.Triad, t.PostCourier, k.Triad, x.v2)
			from	tvp.Duad#Slice(@slip, default, default) x
			cross	apply loc.RefNbr#Cast(x.v1)   m
			cross	apply core.MIC#IdOf(m.Number) i
			cross	apply core.RefNbr#Type() t
			cross	apply tvp.Spr#Const()    k
			for		xml path(N'')
		)
		select	@refNbrSlip=Tvp from cte cross apply tvp.Spr#Purify(text, default);
		exec	core.RefNbr#Merge @slip=@refNbrSlip;
		;
		with	cte(text) as
		(
			select	[text()]=concat(N',', x.v1)
			from	tvp.Triad#Slice(@refNbrSlip, default, default) x
			cross	apply tvp.Spr#Const() k
			for		xml path(N'')
		)
		select	@idsInCsv=Tvp from cte cross apply tvp.Spr#Purify(text, 1);

		declare	@actionID I32=(select CfmSurrenderByImport from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@idsInCsv, @actionID=@actionID, @tenancy=@tenancy;

		select	@result=@refNbrSlip;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
