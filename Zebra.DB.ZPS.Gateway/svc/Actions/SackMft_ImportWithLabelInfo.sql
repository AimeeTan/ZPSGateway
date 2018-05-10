/*
	@slip    = Block[Many[Duad<MIC, TrkNbr>], Many[LabelInfo]];
	@context = Quad<HubID, POA, BrokerID, Mawb>
*/
-- Eva
CREATE PROCEDURE [svc].[SackMft$ImportWithLabelInfo](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;

		declare	@importSlip tvp;
		select	@importSlip=Tvp
		from	tvp.Block#At(1, @slip, default, default);
		execute	svc.SackMft$Import @slip=@importSlip, @context=@context, @tenancy=@tenancy;

		declare	@labelTvp tvp;
		select	@labelTvp=Tvp
		from	tvp.Block#At(2, @slip, default, default);
		with	cteSlip as
		(
			select	m.MatterID, Type=k.ShippingLabelInfo, Info=i.Piece
			from	tvp.Duad#Slice(@importSlip, default, default) x
			join	tvp.Many#Slice(@labelTvp)     i on i.Seq=x.Seq
			cross	apply loc.RefNbr#Cast(x.v1)   n
			cross	apply core.MIC#IdOf(n.Number) m
			cross	apply core.RefInfo#Type()     k
		)
		merge	into core._RefInfo as o using cteSlip as n
		on		(o.MatterID=n.MatterID and o.Type=n.Type)
		when	    matched and n.Info>N'' then update set o.Info=n.Info
		when	not matched	and n.Info>N'' then insert (  MatterID,   Type,   Info)
												  values (n.MatterID, n.Type, n.Info);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END