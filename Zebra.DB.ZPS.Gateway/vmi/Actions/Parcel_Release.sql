/*
@result=Triad<Comma[MatterID], ReleasedSkus>
*/
--Smile
CREATE PROCEDURE [vmi].[Parcel$Release](@result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
		BEGIN TRY
		BEGIN	TRAN;
	
		declare	@source E8=(select eVMI		       from core.Source#ID())
		,		@qtype	E8=(select ReadyForRelease from core.Queue#Type());
		execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out;

		declare	@exeSlip tvp;
		with cteSkuOnHeld(text) as
		(
			select	[text()]=concat(c.Many, TenantAlias, c.Tuplet
										  , g.Sku,		 c.Tuplet 
										  , g.SkuBatch,	 c.Tuplet
										  , g.Condition, c.Tuplet
										  , l.LineQty)
			from	tvp.Quad#Slice(@result, default, default) q
			cross	apply core.RefInfo#Type() k
			join	core.RefInfo#Raw()        i on i.MatterID=cast(q.v1 as bigint) and i.Type=k.DeclaredInfo
			join	shpt.Parcel#Base()        m on m.ID=i.MatterID
			join	core.Party#Raw()          p on p.ID=m.SiteID
			join	core.Tenant#Raw()         t on t.ID=p.PID
			cross	apply loc.TenantAlias#Rectify(t.Alias) s
			cross	apply tvp.Mucho#Slice(i.Info)          d
			cross	apply loc.LineInfo#Of(d.Piece)         l
			cross	apply loc.GoodsInfo#Of(l.GoodsInfo)    g
			cross	apply tvp.Spr#Const()                  c
			for	xml path(N'')
			
		)
		select	@exeSlip=d.Tvp
		from	cteSkuOnHeld x cross apply tvp.Spr#Purify(text, default) t
		cross	apply tvp.Duad#Make(@source, t.Tvp)                      d;

		--execute	[$(FLUX_SERVER)].[$(FLUX_WMS)].svc.SkuOnHold$Release @exeSlip;

		
		;with cte(text) as
		(
			select	[text()]=concat(N',', q.v1)		
			from	tvp.Quad#Slice(@result, default, default) q				
			for		xml path(N'')
		)
		select	@result=s.Tvp from cte                     x
		cross	apply tvp.Spr#Purify(text, 1)              d
		cross	apply tvp.Triad#Make(d.Tvp, @exeSlip, N'') s;
	
		COMMIT	TRAN;
		END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END