/*
@slip   = ParcelID
@result = Many[Duad<Seq, MIC>]
*/
--Eva, Smile
CREATE PROCEDURE [hub].[ShippingPlan$Comply](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- Transit Origion:
		declare	@parcelID I64=@slip;
		declare	@actionID E32=(select ComplyWithShippingPlan from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@slip, @actionID=@actionID, @tenancy=@tenancy, @beAffected=1;

		-- Promote Original to ShippingPlan:
		declare	@shippingPlan E8=(select ShippingPlan from core.Matter#Type());
		with cte as
		(
			select	Type
			from	core.Matter#Raw()
			where	ID=@parcelID
		)
		update	cte set Type=@shippingPlan;


		-- Init. Parcels from ShippingPlan:
		declare	@shippingPlanInfo tvp=(select Info from core.RefInfo#Type() k cross apply core.RefInfo#Of(@parcelID, k.ShippingPlanInfo))
		,		@concurredInfo    tvp=(select Info from core.RefInfo#Type() k cross apply core.RefInfo#Of(@parcelID, k.ConcurredInfo))
		,		@brkgInfo         tvp=(select Info from core.RefInfo#Type() k cross apply core.RefInfo#Of(@parcelID, k.BrokerageInfo))
		,		@newCnt int;
		select	@newCnt=count(*) from tvp.Bag#Slice(@shippingPlanInfo);

		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(@newCnt);
		
		declare	@source E8,       @svcType I32,       @lastMilerID I32, @siteID I32, @contractID I32
		,		@svcZone E8,      @svcClass E8,       @poa char(3), @routeID I32
		select	@source=Source,   @svcType=SvcType,   @lastMilerID =LastMilerID, @contractID=ContractID
		,		@svcZone=SvcZone, @svcClass=SvcClass, @poa=POA,     @routeID=RouteID
		,		@siteID=SiteID
		from	shpt.Parcel#Base() where ID=@parcelID;

		declare	@userID I32=(select	UserID from	loc.Tenancy#Of(@tenancy));

		declare	@stateID I32=(
								select	t.ToStateID
								from	tms.SvcType#Raw()      x
								cross	apply core.Action#ID() k
								join	core.Transition#Raw()  t on t.OnStateID=x.InitStateID and t.ActionID=k.HubCheckIn
								where	x.ID=@svcType

							 )
		 ;--ToAaron: get stateID by source or route?

		declare	@type    E8 =(select Parcel from core.Matter#Type())
		,		@stage   E32 =(select Stage  from core.Stage#Of(@stateID));
		insert	core._Matter
		(		ID, AID,       PosterID,  StateID,  Stage,  Source,  Type, PostedOn   )
		select	ID, @parcelID, @siteID,  @stateID, @stage, @source, @type, getutcdate()
		from	@idSeqs;

		execute	core.Activity#AddByIdSeqs @idSeqs=@idSeqs, @stateID=@stateID, @userID=@userID;

		-- Add RefNbrs
		execute	core.RefNbr#AddMIC     @idSeqs=@idSeqs, @source=@source, @type=@type;
		insert	core._RefNbr(MatterID, Type,        Number)
		select				 m.ID,     t.ClientRef, c.v1
		from	@idSeqs                       m
		join	tvp.Bag#Slice(@concurredInfo) p on p.Seq=m.Seq
		cross	apply tvp.Pair#Of(p.Piece)    c
		cross	apply core.RefNbr#Type()      t where len(c.v1)>0;

		-- Add RefInfos
		declare	@idInfo tvp,    @shprInfo tvp,    @cneeInfo tvp;
		select	@idInfo=i.Info, @shprInfo=s.Info, @cneeInfo=c.Info
		from	core.RefInfo#Type() k
		outer	apply core.RefInfo#Of(@parcelID, k.IDInfo)   i
		cross	apply core.RefInfo#Of(@parcelID, k.ShprInfo) s
		cross	apply core.RefInfo#Of(@parcelID, k.CneeInfo) c;
		with	cte as
		(
			select	MatterID=m.ID, Type=t.IDInfo, Info=@idInfo
			from	@idSeqs                   m
			cross	apply core.RefInfo#Type() t
			UNION	ALL
			select	MatterID=m.ID, Type=t.ShprInfo, Info=@shprInfo
			from	@idSeqs                   m
			cross	apply core.RefInfo#Type() t
			UNION	ALL
			select	MatterID=m.ID, Type=t.CneeInfo, Info=@cneeInfo
			from	@idSeqs                   m
			cross	apply core.RefInfo#Type() t
			UNION	ALL
			select	MatterID=m.ID, Type=t.DeclaredInfo, Info=p.Piece
			from	@idSeqs                          m
			cross	apply core.RefInfo#Type()        t
			join	tvp.Bag#Slice(@shippingPlanInfo) p on p.Seq=m.Seq
		)
		insert	core._RefInfo(MatterID, Type, Info)
		select				  MatterID, Type, Info from cte where len(Info)>0;

		with cteInfo as
		(
			select	MatterID=m.ID, m.Seq, Info=concat(e.v1, k.Triad, e.v2, k.Triad,  s.Piece)

			from	tvp.Spr#Const() k, @idSeqs       m
			join	tvp.Bag#Slice(@shippingPlanInfo) p on p.Seq=m.Seq
			cross	apply tvp.Mucho#Slice(p.Piece)   s
			join	tvp.Mucho#Slice(@brkgInfo)       b on b.Seq=s.Seq
			cross	apply tvp.Triad#Of(b.Piece, default)      e
		), cteMixed as
		(
			select	MatterID, Info=(select concat(k.Mucho, o.Info) from tvp.Spr#Const() k, cteInfo o where o.MatterID=x.MatterID  FOR XML PATH(N''))
			from	cteInfo x
			group	by MatterID

		)
		insert	core._RefInfo(MatterID, Type, Info)
		select	MatterID, k.BrokerageInfo, t.Tvp 
		from	core.RefInfo#Type() k, cteMixed x cross	apply tvp.Spr#Purify(x.Info, default) t;
		
		insert	shpt._Parcel
		(		ID, BatchID,  RouteID,  LastMilerID,  SvcType,  SvcZone,  SvcClass, POA,   ContractID)
		select	ID, 0,       @routeID, @lastMilerID, @svcType, @svcZone, @svcClass, @poa, @contractID
		from	@idSeqs;

		-- Result:
		with	cte(text) as
		(
			select	[text()]=concat(k.Many,  i.Seq, k.Duad, r.Number)
			from	@idSeqs i
			join	core.RefNbr#Raw()        r on r.MatterID=i.ID
			cross	apply core.RefNbr#Type() t
			cross	apply tvp.Spr#Const()    k
			where	r.Type=t.MIT for xml path(N'')
		) select	@result=Tvp  from cte cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
