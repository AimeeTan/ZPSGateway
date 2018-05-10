-- AaronLiu
CREATE PROCEDURE [api].[PolyCallback$Dequeue](@result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@source E8=(select eShip		from core.Source#ID())
		,		@qtype	E8=(select PolyCallback from core.Queue#Type());
		execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out;

		with cte(text) as
		(
			select	[text()]=concat
			(	
				k.Entry, x.ID,
				k.Block, x.SiteID,
				k.Block, x.RefNbrs,
				k.Block, i.Info
			)
			from	tvp.Spr#Const()	k, tvp.Quad#Slice(@result, default, default) q
			join	shpt.Parcel#Deep()		    x on x.ID=cast(q.v1 as bigint)	
			cross	apply core.RefInfo#Type()   t
			cross	apply core.RefInfo#Of(x.ID, t.IDInfo) i
			for		xml path(N'')
		)
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END