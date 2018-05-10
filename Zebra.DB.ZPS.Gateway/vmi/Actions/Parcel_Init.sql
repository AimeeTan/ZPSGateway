/*
@slip    = Entry[Block<RefNbr, PreCourier, Shipper, Consignee, LineInfo, IDNbr, Weight, BrkgInfo, PostCourier, AuxiliaryOrderInfo>]
@context = Tuplet<Source, SvcType, HubID, TenantAlias, Quad[Sku, BatchNo, IsDefective, SkuQty], ErorCnt, Errors>
@result  = Comma[MatterID]
*/
--Smile
CREATE PROCEDURE [vmi].[Parcel$Init](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		-- 0.	Tenancy & Contexts:
		declare	@siteID I32,    @userID I32;
		select	@siteID=SiteID, @userID=UserID
		from	loc.Tenancy#Of(@tenancy) x
		join	core.Party#Raw()         p on x.AID=p.ID;

		declare	@source E8, @hubID int, @hubAlias loc.Alias
		,		@errorCnt int,   @errors json,  @poa char(3), @svcType I32
		,		@routeID I32,    @courierID I32,              @stateID I32
		,       @contractID I32, @initQueue varchar(20);
		select	@source=v1, @hubID=v3,  @hubAlias=p.Alias
		,		@errorCnt=x.v6, @errors=x.v7,  @poa=r.POA,   @svcType=t.ID
		,		@routeID=r.RouteID, @courierID=r.CourierID, @stateID=t.InitStateID
		,		@contractID=c.ID, @initQueue=t.InitQueue
		from	tvp.Tuplet#Of(@context, default)                        x
		join	core.Party#Raw()                                        p on p.ID=cast(x.v3 as int)
		cross	apply tms.SvcType#For(cast(x.v2 as int), @siteID)       t
		cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)             r
		cross	apply acct.Contract#For(@siteID, cast(x.v1 as tinyint)) c;


		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	ID=next value for core.MatterSeq,   Seq=Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		declare	@type  E8 =(select Parcel from core.Matter#Type())
		,		@stage E32=(select Stage  from core.Stage#Of(@stateID));
		insert	core._Matter
		(		ID,  PosterID,  StateID,  Stage,  Source,  Type, PostedOn   )
		select	ID,  @siteID,  @stateID, @stage, @source, @type, getutcdate()
		from	@idSeqs;

		execute	core.Activity#AddByIdSeqs @idSeqs=@idSeqs, @stateID=@stateID, @userID=@userID;

		-- 1.1	Add OutboundQ:
		with cteq as
		(
			select	QueueType=try_cast(c.Piece as tinyint)
			from	tvp.Comma#Slice(@initQueue) c
		)
		insert	core._OutboundQ
			    (ToSource, QueueType, MatterID,  StateID)
		select	s.Source,  QueueType, ID, @stateID
		from	@idSeqs x, cteq q
		cross	apply core.Source#Rectify(@source, QueueType) s;

		-- 2.	Add RefNbrs & RefInfos:
		declare	@clientRef    E8, @preCourier E8, @postCourier E8
		,		@cneeInfo     E8, @shprInfo   E8, @idInfo      E8
		,		@declaredInfo E8, @brkgInfo   E8, @auxiliaryOrderInfo E8;
		select	@clientRef=n.ClientRef, @preCourier=n.PreCourier, @postCourier=n.PostCourier    
		,		@cneeInfo=i.CneeInfo,   @shprInfo=i.ShprInfo,     @idInfo=i.IDInfo
		,		@declaredInfo=i.DeclaredInfo, @brkgInfo=i.BrokerageInfo
		,		@auxiliaryOrderInfo=i.AuxiliaryOrderInfo
		from	core.RefNbr#Type() n, core.RefInfo#Type() i

--> NEW:
		declare	@cells dbo.Cells;
		insert	@cells
		(		  Col,   Row,   Val)
		select	c.Col,  x.ID, c.Val
		from	@idSeqs x join tvp.Cell#Slice(@slip, default, default) c on x.Seq=c.Row

		execute	core.RefNbr#AddMIC @idSeqs=@idSeqs, @source=@source, @type=@type;

		execute	core.RefNbr#AddViaCells  @column=1, @cells=@cells, @type=@clientRef;
		execute	core.RefNbr#AddViaCells  @column=2, @cells=@cells, @type=@preCourier;
		execute	core.RefNbr#AddViaCells  @column=9, @cells=@cells, @type=@postCourier;

		execute	core.RefInfo#AddViaCells @column=3, @cells=@cells,  @type=@shprInfo;
		execute	core.RefInfo#AddViaCells @column=4, @cells=@cells,  @type=@cneeInfo;
		execute	core.RefInfo#AddViaCells @column=5, @cells=@cells,  @type=@declaredInfo;
		execute	core.RefInfo#AddViaCells @column=6, @cells=@cells,  @type=@idInfo;
		execute	core.RefInfo#AddViaCells @column=8, @cells=@cells,  @type=@brkgInfo;
		execute	core.RefInfo#AddViaCells @column=10, @cells=@cells, @type=@auxiliaryOrderInfo;

		-- 3.	Add Batch & Parcels:
		declare	@batchID I64;
		execute	shpt.Batch#Create @id=@batchID out, @siteID=@siteID, @errorCnt=@errorCnt, @errors=@errors;

		insert	shpt._Parcel
		(		ID,     BatchID,  RouteID,  LastMilerID,  SvcType, SvcZone, SvcClass,  POA, DeclaredWt, Weight,  ContractID,  RcvHubID)
		select	x.Row, @batchID, @routeID, @courierID,   @svcType, 1,       1,        @poa, x.Val,      0,      @contractID, @hubID
		from	@cells x where x.Col=7
--> ORI:
/*
		execute	core.RefNbr#AddMIC @idSeqs=@idSeqs, @source=@source, @type=@type;

		execute	core.RefNbr#AddBlock  @index=1, @idSeqs=@idSeqs, @slip=@slip, @type=@clientRef;
		execute	core.RefNbr#AddBlock  @index=2, @idSeqs=@idSeqs, @slip=@slip, @type=@preCourier;
		execute	core.RefNbr#AddBlock  @index=9, @idSeqs=@idSeqs, @slip=@slip, @type=@postCourier;

		execute	core.RefInfo#AddBlock @index=3, @idSeqs=@idSeqs, @slip=@slip, @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=4, @idSeqs=@idSeqs, @slip=@slip, @type=@cneeInfo;
		execute	core.RefInfo#AddBlock @index=5, @idSeqs=@idSeqs, @slip=@slip, @type=@declaredInfo;
		execute	core.RefInfo#AddBlock @index=6, @idSeqs=@idSeqs, @slip=@slip, @type=@idInfo;
		execute	core.RefInfo#AddBlock @index=8, @idSeqs=@idSeqs, @slip=@slip, @type=@brkgInfo;

		-- 3.	Add Batch & Parcels:
		declare	@batchID I64;
		execute	shpt.Batch#Create @id=@batchID out, @siteID=@siteID, @errorCnt=@errorCnt, @errors=@errors;

		insert	shpt._Parcel
		(		ID,        BatchID,  RouteID,  LastMilerID, SvcType, SvcZone, SvcClass,  POA, DeclaredWt,  Weight, ContractID,  RcvHubID)
		select	x.Master, @batchID, @routeID, @courierID,  @svcType, 1,       1,        @poa, x.House,     0,     @contractID, @hubID
		from	tvp.Block#FoldT(7, @idSeqs, @slip, default, default) x 
*/	
		-- 4.	Result:
		;with cte(text) as
		(
			select	[text()]=concat(N',', q.ID)		
			from	@idSeqs     q				
			for		xml path(N'')
		)
		select	@result=d.Tvp from cte                     x
		cross	apply tvp.Spr#Purify(text, 1)              d;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END