/*
@slip    =Many[Duad<TrackingNbr,HasWmsVoid>]
@result  =Triad<Pair<TenantAlias, Duad[RcvHub, OrderNbr]>, ReleasedSkus>
*/
--Smile
CREATE PROCEDURE [vmi].[Parcel$Void](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;
	    
		declare	@userID I32,    @roleID I32,    @tenantAlias loc.Alias;
		select	@userID=UserID, @roleID=RoleID, @tenantAlias=TenantAlias
		from	loc.Tenancy#Of(@tenancy) x
		join	core.Party#Raw()         p on x.AID=p.ID
		cross	apply loc.TenantAlias#Rectify(p.Alias) t;

	    declare	@actionID I32=(select VoidParcel from core.Action#ID());

		--	1.Parcel Transit
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* 
		from	tvp.Duad#Slice(@slip, default, default) x
		cross	apply loc.RefNbr#Cast(x.v1)             b
		cross	apply core.RefNbr#ScanOne(b.Number, default, default)  n
		cross	apply shpt.Parcel#Tobe(n.MatterID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		declare	@clientRef E8=(select ClientRef from core.RefNbr#Type());
		declare	@voidInfo  E8=(select VoidInfo  from core.RefInfo#Type());
		--	2.  Insert VoidInfo
		with cteVoidInfo as
		(
			select	r.MatterID, Info=Number
			from	@spec                    x
			join	core.RefNbr#Raw()        r on r.MatterID=x.MatterID and r.Type=@clientRef
		)
		insert	into core._RefInfo(MatterID, Type, Info) select MatterID, @voidInfo, Info
		from	cteVoidInfo;

		declare	@exeResult tvp;
		;with cteResult(text) as
		(
			select	[text()]=concat(k.Many, r.Alias, k.Duad, m.Number)
			from	@spec x
			join	shpt.Parcel#Raw()        s on s.ID=x.MatterID
			join	core.Party#Raw()         r on r.ID=s.RcvHubID
			cross	apply core.RefNbr#Type() t
			join	core.RefNbr#Raw()        m on m.MatterID=s.ID and m.Type=t.ClientRef
			cross	apply tvp.Spr#Const()    k
			for		xml path(N'')
		)
		select	@exeResult=r.Tvp 
		from	cteResult 
		cross	apply tvp.Spr#Purify(text, default)  x
		cross	apply tvp.Pair#Make(@tenantAlias, x.Tvp) r
		;

		-- 3.	delete ClientRefNbr		
		delete	from core._RefNbr 
		where	Type=@clientRef	and MatterID in (select MatterID from @spec)
		;

		
		declare	@exeSlip tvp;
		declare	@source E8=(select eVMI from core.Source#ID());
		with cteSkuOnHeld(text) as
		(
			select	[text()]=concat(c.Many, @tenantAlias, c.Tuplet
										  , g.Sku,		  c.Tuplet 
										  , g.SkuBatch,	  c.Tuplet
										  , g.Condition,  c.Tuplet
										  , l.LineQty)
			from	tvp.Duad#Slice(@slip, default, default) x
			cross	apply loc.RefNbr#Cast(x.v1)             b
			cross	apply core.RefNbr#ScanOne(b.Number, default, default)  n
			join	@spec                     q on q.MatterID=n.MatterID
			cross	apply core.RefInfo#Type() k
			join	core.RefInfo#Raw()        i on i.MatterID=q.MatterID and i.Type=k.DeclaredInfo
			join	shpt.Parcel#Base()        m on m.ID=i.MatterID
			cross	apply tvp.Mucho#Slice(i.Info)          d
			cross	apply loc.LineInfo#Of(d.Piece)         l
			cross	apply loc.GoodsInfo#Of(l.GoodsInfo)    g
			cross	apply tvp.Spr#Const()                  c
			cross	apply core.State#ID()                  s
			where	cast(x.v2 as bit)=0 and q.OnStateID<s.AwaitingMeasurement  --Hack 
			for	xml path(N'')
		)
		select	@exeSlip=d.Tvp
		from	cteSkuOnHeld x cross apply tvp.Spr#Purify(text, default) t
		cross	apply tvp.Duad#Make(@source, t.Tvp)                      d;

		select	@result=Tvp from tvp.Triad#Make(@exeResult, @exeSlip, N'');
		--execute	[$(FLUX_SERVER)].[$(FLUX_WMS)].svc.SkuOnHold$Release @exeSlip;
	
		COMMIT TRAN;			
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END