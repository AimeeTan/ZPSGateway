-- AaronLiu
CREATE PROCEDURE [api].[PostCourier$DequeueForTC](@result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@source E8=(select InfoPath		  from core.Source#ID())
		,		@qtype	E8=(select PostCourierApi from core.Queue#Type());
		execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out;

		with cte(text) as
		(
			select	[text()]=concat
			(	
				k.Many, x.ID,
				k.Quad, x.RouteID,
				k.Quad, x.LastMilerID,
				k.Quad, n.Number
			)
			from	tvp.Spr#Const() k, tvp.Quad#Slice(@result, default, default) q
			join	shpt.Parcel#Deep()		   x on x.ID=cast(q.v1 as bigint)
			cross	apply core.RefNbr#Type()   t
			cross	apply core.RefNbr#Of(x.ID, t.PostCourier) n
			for		xml path(N'')
		)
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
