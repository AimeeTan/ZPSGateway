/*
	@slip = Many[Duad<Number, Mucho<FilebankID>>]

	SnapshotInfo = Mucho<FilebankID>
*/
-- AaronLiu
CREATE PROCEDURE [api].[Snapshot$Merge](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		with	cte(text) as
		(
			select	[text()]= concat
			(
				k.Many,  m.MatterID,
				k.Triad, t.SnapshotInfo,
				k.Triad, x.v2
			)
			from	tvp.Spr#Const() k, tvp.Duad#Slice(@slip, default, default) x
			cross	apply core.RefNbr#ScanOne(x.v1, default, default)		   m
			cross	apply core.RefInfo#Type() t
			for		xml path(N'')
		)
		select	@slip=Tvp from cte cross apply tvp.Spr#Purify(text, default);
		execute	core.RefInfo#Merge @slip=@slip;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END