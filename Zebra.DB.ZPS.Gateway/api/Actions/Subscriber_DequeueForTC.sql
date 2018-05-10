-- AaronLiu
CREATE PROCEDURE [api].[Subscriber$DequeueForTC](@result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@source E8=(select InfoPath				  from core.Source#ID())
		,		@qtype	E8=(select SubscriberRegister=207 from core.Queue#Type());
		execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out;

		with cte(text) as
		(
			select	[text()]=concat
			(	
				k.Many,	q.v1,
				k.Quad,	x.RouteID,
				k.Quad, m.Number,
				k.Quad, a.RefNbr
			)
			from	tvp.Spr#Const() k, tvp.Quad#Slice(@result, default, default) q
			join	shpt.Parcel#Deep()		   x on x.ID=cast(q.v1 as bigint)
			cross	apply core.RefNbr#Type()   t
			cross	apply core.RefNbr#Of(x.ID, t.MIT) m
			join	api.ActivitySubscription#Raw() a on  x.ID=a.MatterID
			for		xml path(N'')
		)
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
