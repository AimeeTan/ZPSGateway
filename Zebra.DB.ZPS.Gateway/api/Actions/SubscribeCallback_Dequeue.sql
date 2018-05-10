-- Jim Qiu, Smile, AaronLiu
CREATE PROCEDURE [api].[SubscribeCallback$Dequeue](@result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@source	E8=(select eShip             from core.Source#ID())
		,		@qtype	E8=(select SubscribeCallback from core.Queue#Type());
		execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out;

		with cte(text) as
		(
			select	[text()]=concat
			(
				k.Many,  x.ID,          k.Quire, x.MIC,         k.Quire, x.FlightNbr,
				k.Quire, x.POA,         k.Quire, x.POD,         k.Quire, x.LastMilerID,
				k.Quire, x.PostCourier, k.Quire, x.RcvHubAlias, k.Quire, a.Stage,
				k.Quire, s.RefNbr,		k.Quire, a.UtcTime,		k.Quire, a.UtcOffset,
				k.Quire, x.RouteID
			)
			from	tvp.Spr#Const() k, tvp.Quad#Slice(@result, default, default) q
			join	svc.Parcel$ListForCainiao()    x on x.ID=cast(v1 as bigint)
			cross	apply core.Activity#TrackSpecific(  x.ID,cast(v2 as    int)) a
			join	api.ActivitySubscription#Raw() s on s.MatterID=x.ID		
			for		xml path(N'')
		)
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
