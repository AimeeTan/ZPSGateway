/*
@slip = Quad<ParcelID, LastMilerAlias, LastMilerNbr, ShippingLabelAncillaries:Dozen>
*/
--PeterHo, Eva
CREATE PROCEDURE [api].[Parcel$RcvBrkgAcceptance](@slip tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		/*
		declare	@matterID tvp,  @mergeSlip tvp;
		select	@matterID=d.v1, @mergeSlip=t.Tvp
		from	core.RefNbr#Type() k
		cross	apply tvp.Duad#Of(@slip, default) d
		cross	apply tvp.Triad#Make(d.v1, k.PostCourier, d.v2) t
		execute	core.RefNbr#Merge @slip=@mergeSlip;
		*/

		declare	@parcelID tvp, @lastMilerNbr tvp, @ancillaries tvp, @lastMilerID I64;
		select	@parcelID=v1,  @lastMilerNbr=v3,  @ancillaries=v4,  @lastMilerID=c.CourierID
		from	tvp.Quad#Of(@slip, default) cross apply tms.Courier#IdOfAlias(v2) c;

		if (@lastMilerID is null or @lastMilerID=0)
			execute	dbo.Assert#Fail @msg=N'The alias of LastMiler can not be found.';

		declare	@nbrSlip tvp=
		(
			select	Tvp   from core.RefNbr#Type() k
			cross	apply tvp.Triad#Make(@parcelID, k.PostCourier, @lastMilerNbr)
		);
		execute	core.RefNbr#Merge @slip=@nbrSlip;
		
		declare	@infoSlip tvp=
		(
			select	t.Tvp from core.RefInfo#Type() k
			cross	apply tvp.Trio#Make(@lastMilerID, @ancillaries, '') p
			cross	apply tvp.Triad#Make(@parcelID, k.ShippingLabelInfo, p.Tvp) t
		);
		execute	core.RefInfo#Merge @slip=@infoSlip;

		declare	@daemon   tvp=null;
		declare	@actionID I32=(select ReceiveBrkgAcceptance from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@parcelID, @actionID=@actionID, @tenancy=@daemon;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
