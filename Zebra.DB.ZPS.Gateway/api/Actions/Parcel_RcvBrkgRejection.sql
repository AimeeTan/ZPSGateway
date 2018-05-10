/*
@slip = Many[Duad<ParcelID, ErrorMsg>]
@todo : Many[Duad<ParcelID, ErrorCode>]
*/
--PeterHo, Eva
CREATE PROCEDURE [api].[Parcel$RcvBrkgRejection](@slip tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@infoSlip tvp=
		(
			select	t.Tvp from core.RefInfo#Type() k
			cross	apply tvp.Duad#Slice(@slip, default, default) x
			cross	apply tvp.Trio#Make(0, '', x.v2) p
			cross	apply tvp.Triad#Make(x.v1, k.ShippingLabelInfo, p.Tvp) t
		);
		execute	core.RefInfo#Merge @slip=@infoSlip;

		declare	@idsInCsv tvp;
		with	cte(text) as
		(
			select	[text()]=concat(N',', x.v1)
			from	tvp.Duad#Slice(@slip, default, default) x for xml path(N'')
		)
		select	@idsInCsv=Tvp from cte cross apply tvp.Spr#Purify(text, 1);

		declare	@daemon   tvp=null;
		declare	@actionID I32=(select ReceiveBrkgRejection from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@idsInCsv, @actionID=@actionID, @tenancy=@daemon;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
