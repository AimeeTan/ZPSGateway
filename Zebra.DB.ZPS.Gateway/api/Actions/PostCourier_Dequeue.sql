-- AaronLiu, Smile
CREATE PROCEDURE [api].[PostCourier$Dequeue](@result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;

	select	@result=N'';
	/*
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
				k.Mucho,  x.ID,
				k.Tuplet, x.SvcType,
				k.Tuplet, x.RefNbrs,
				k.Tuplet, x.CourierCode,
				k.Tuplet, isnull(a.RefNbr,N'')
			)
			from	tvp.Spr#Const() k, tvp.Quad#Slice(@result, default, default) q
			join	shpt.Parcel#Deep()                  x on x.ID=cast(q.v1 as bigint)
			left	join api.ActivitySubscription#Raw() a on x.ID=a.MatterID			
			for		xml path(N'')
		)
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
	*/
END
