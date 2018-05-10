/*
@slip    = Entry[Block< Quad<SiteID, SvcType, RchHubAlias, POA>
				, RefNbr
				, Shpr
				, Cnee
				, Mucho[LineInfo]
				, ID
				, Mucho[Duad<Precourier, Weight>]>
				, AddOnSvc]
@context = batchID
*/
--Smile
CREATE PROCEDURE [shpt].[Parcel#UnfiledMPSInitByPlatform](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- 0.	Contexts:
		declare	@siteID I32,    @userID I32,    @source tinyint;
		select	@siteID=SiteID, @userID=UserID, @source=p.Source
		from	loc.Tenancy#Of(@tenancy) x
		join	core.Party#Raw()         p on p.ID=x.UserID;

		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		declare	@type  E8=(select MasterParcel from core.Matter#Type())
		,		@spec core.TransitionSpec;
		insert	core._Matter
		(		ID,  PosterID,   StateID,       Stage,  Source,  Type, PostedOn    )
		output	inserted.ID, 0, 0, inserted.StateID, inserted.Stage, inserted.Source, 0, 0 into @spec
		select	x.Master,  cast(q.v1 as int), t.InitStateID, s.Stage, @source,  @type, getutcdate()
		from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default)        x 
		cross	apply tvp.Quad#Of(x.House, default)                         q	
		cross	apply tms.SvcType#For(cast(q.v2 as int), cast(q.v1 as int)) t
		cross	apply core.Stage#Of(t.InitStateID)                          s

		execute	core.Activity#AddBySpec      @spec=@spec, @userID=@userID;
		

		-- 2.	Add RefNbrs & RefInfos:
		declare	@clientRef E8,  @shprInfo E8,  @cneeInfo E8,  @preCourier E8,  @IDInfo E8
		,		@declaredInfo E8,  @brokerageInfo E8, @addOnSvcInfo E8;
		select	@clientRef=n.ClientRef, @shprInfo=i.ShprInfo, @cneeInfo=i.CneeInfo
		,		@preCourier=n.PreCourier, @IDInfo=i.IDInfo, @declaredInfo=i.DeclaredInfo
		,		@brokerageInfo=i.BrokerageInfo, @addOnSvcInfo=I.AddOnSvcInfo
		from	core.RefNbr#Type() n,   core.RefInfo#Type() i;

		execute	core.RefNbr#AddMIC       @idSeqs=@idSeqs, @source=@source,  @type=@type;

		execute	core.RefNbr#AddBlock  @index=2, @idSeqs=@idSeqs, @slip=@slip, @type=@clientRef;		
		execute	core.RefInfo#AddBlock @index=3, @idSeqs=@idSeqs, @slip=@slip, @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=4, @idSeqs=@idSeqs, @slip=@slip, @type=@cneeInfo;
		execute	core.RefInfo#AddBlock @index=5, @idSeqs=@idSeqs, @slip=@slip, @type=@declaredInfo;
		execute	core.RefInfo#AddBlock @index=6, @idSeqs=@idSeqs, @slip=@slip, @type=@IDInfo;
		execute	core.RefInfo#AddBlock @index=8, @idSeqs=@idSeqs, @slip=@slip, @type=@addOnSvcInfo;
		insert	into core._RefInfo(MatterID, Type, Info)
		select	x.Master, @brokerageInfo, b.BrokerageInfo
		from	tvp.Block#FoldT(5, @idSeqs, @slip, default, default) x
		cross	apply loc.Declared$ToBrokerage(x.House, default)	 b	

		-- 3.	Add Matser Parcels:
		declare	@batchID I64=(@context);
		
		insert	shpt._Parcel
		(		ID, BatchID,  RouteID, LastMilerID, SvcType,
				SvcZone, SvcClass,  POA, RcvHubID, ContractID)
		select	x.Master, @batchID, isnull(d.RouteID, r.RouteID), r.CourierID,  t.ID,
				1, 1,  iif(nullif(q.v4, '') is null, r.POA, q.v4), isnull(h.ID, 0), c.ID
		from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default) x 
		cross	apply tvp.Quad#Of(x.House, default)                  q
		cross	apply core.Party#Type()                              e
		left	join  core.Party#Raw()                               h on h.Alias=q.v3 and h.Type=e.ZebraHub
		cross	apply tms.SvcType#For(cast(q.v2 as int), cast(q.v1 as int)) t
		outer	apply tms.SvcRoute#For(t.ID, cast(q.v4 as char(3)))  d
		cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)          r
		cross	apply acct.Contract#For(cast(q.v1 as int), @source)  c;

		--4.	init HouseParcel
		declare	@houseSeqs I64Seqs; insert @houseSeqs(ID, Seq)
		select  next value for core.MatterSeq, x.Seq*100 + d.Seq
		from	tvp.Block#FoldT(7, @idSeqs, @slip, default, default) x
		cross	apply tvp.Mucho#Slice(x.House)                       p
		cross	apply tvp.Duad#Slice(p.Piece, default, default)      d
        ;

		select	@type=HouseParcel from core.Matter#Type();
		insert	core._Matter
		(		ID,  AID, PosterID, StateID, Stage, Source, Type, PostedOn    )
		output	inserted.ID, 0, 0, inserted.StateID, inserted.Stage, inserted.Source, 0, 0 into @spec
		select	h.ID, x.Master,  m.PosterID, m.StateID, m.Stage, @source,  @type, getutcdate()
		from	tvp.Block#FoldT(7, @idSeqs, @slip, default, default) x
		cross	apply tvp.Mucho#Slice(x.House)                       p
		cross	apply tvp.Duad#Slice(p.Piece, default, default)      d
		join	@houseSeqs                                           h on h.Seq=x.Seq*100 + d.Seq
		join	core.Matter#Raw()                                    m on m.ID=x.Master

		execute	core.Activity#AddBySpec      @spec=@spec, @userID=@userID;

		execute	core.RefNbr#AddMIC       @idSeqs=@houseSeqs, @source=@source,  @type=@type;
		insert	into core._RefNbr(MatterID, Type, Number)
		select	h.ID, @preCourier, d.v1
		from	tvp.Block#FoldT(7, @idSeqs, @slip, default, default) x
		cross	apply tvp.Mucho#Slice(x.House)                       p
		cross	apply tvp.Duad#Slice(p.Piece, default, default)      d
		join	@houseSeqs                                           h on h.Seq=x.Seq*100 + d.Seq
		;
		insert	into shpt._Parcel
		(		ID,   BatchID,  RouteID,   LastMilerID,  SvcType, SvcZone, SvcClass,  POA,  Weight, RcvHubID,        ContractID)
		select	h.ID, @batchID, r.RouteID, r.LastMilerID, r.SvcType,     1,      1,   r.POA, cast(d.v2 as real),   r.RcvHubID, r.ContractID
		from	tvp.Block#FoldT(7, @idSeqs, @slip, default, default) x
		cross	apply tvp.Mucho#Slice(x.House)                       p
		cross	apply tvp.Duad#Slice(p.Piece, default, default)      d
		join	@houseSeqs                                           h on h.Seq=x.Seq*100 + d.Seq
		join	shpt.Parcel#Raw()                                    r on r.ID=x.Master
		;
		
		-- PreCourier Concern
		declare	@preCouriers tvp;
		with	cte(text) as
		(
			select	[text()]=concat(N',', d.v1)
			from	tvp.Block#At(7, @slip, default, default)		x
			cross	apply tvp.Spr#Const()							k
			cross	apply tvp.Pcs#Slice(x.Tvp, k.Entry)				p
			cross	apply tvp.Mucho#Slice(p.Piece)					m
			cross	apply tvp.Duad#Slice(m.Piece, default, default) d
			for		xml path(N'')
		)
		select	@preCouriers=Tvp from cte cross apply tvp.Spr#Purify(text, 1)
		execute	shpt.PreCourier#Concern @slip=@preCouriers;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
