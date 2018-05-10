/*
@slip    = Entry[Block< Quad<SiteID, SvcType, Weight, RchHubAlias>, RefNbr, PreCourier, ShprInfo, CneeInfo, 
		   Mucho[LineInfo], IDInfo, Mucho[CmdyInfo]>]
@context = Duad<errorCnt, errors>
*/
--Smile, Aaron Liu
CREATE PROCEDURE [api].[Parcel$InitForPlatformUnFiled](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
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

		declare	@errorCnt int, @errors json;
		select	@errorCnt=v1,  @errors=v2
		from	tvp.Duad#Of(@context, default) x
		;

		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		declare	@type  E8=(select Parcel from core.Matter#Type())
		,		@spec core.TransitionSpec;
		insert	core._Matter
		(		ID,  PosterID,   StateID,       Stage,  Source,  Type, PostedOn    )
		output	inserted.ID, 0, 0, inserted.StateID, inserted.Stage, inserted.Source, 0, 0 into @spec
		select	x.Master,  cast(q.v1 as int), t.InitStateID, s.Stage, @source,  @type, getutcdate()
		from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default)       x 
		cross	apply tvp.Quad#Of(x.House, default)                        q
		cross	apply tms.SvcType#For(cast(q.v2 as int), cast(q.v1 as int)) t
		cross	apply core.Stage#Of(t.InitStateID)                          s

		execute	core.Activity#AddBySpec      @spec=@spec, @userID=@userID;
		

		-- 2.	Add RefNbrs & RefInfos:
		declare	@clientRef E8,          @shprInfo E8,         @cneeInfo E8,          @preCourier E8,           @IDInfo E8,       @declaredInfo E8;
		select	@clientRef=n.ClientRef, @shprInfo=i.ShprInfo, @cneeInfo=i.CneeInfo,  @preCourier=n.PreCourier, @IDInfo=i.IDInfo, @declaredInfo=i.DeclaredInfo
		from	core.RefNbr#Type() n,   core.RefInfo#Type() i

		execute	core.RefNbr#AddMIC       @idSeqs=@idSeqs, @source=@source,  @type=@type;

		execute	core.RefNbr#AddBlock  @index=2, @idSeqs=@idSeqs, @slip=@slip, @type=@clientRef;
		execute	core.RefNbr#AddBlock  @index=3, @idSeqs=@idSeqs, @slip=@slip, @type=@preCourier;
		execute	core.RefInfo#AddBlock @index=4, @idSeqs=@idSeqs, @slip=@slip, @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=5, @idSeqs=@idSeqs, @slip=@slip, @type=@cneeInfo;
		execute	core.RefInfo#AddBlock @index=6, @idSeqs=@idSeqs, @slip=@slip, @type=@declaredInfo;
		execute	core.RefInfo#AddBlock @index=7, @idSeqs=@idSeqs, @slip=@slip, @type=@IDInfo;

		declare	@refInfoSlip tvp;
		with	cte(text) as
		(
			select	[text()]=concat(k.Many, x.Master, k.Triad, t.BrokerageInfo, k.Triad, b.BrokerageInfo)
			from	tvp.Block#FoldT(6, @idSeqs, @slip, default, default) x
			join	tvp.Block#FoldT(8, @idSeqs, @slip, default, default) c on x.Seq=c.Seq
			cross	apply loc.Declared$ToBrokerage(x.House, c.House)	 b
			cross	apply core.RefInfo#Type() t
			cross	apply tvp.Spr#Const() k
			for		xml path(N'')
		)
		select	@refInfoSlip=Tvp from cte cross apply tvp.Spr#Purify(text, default);
		execute	core.RefInfo#Merge @slip=@refInfoSlip;

		-- 3.	Add Batch & Parcels:
		declare	@batchID I64;
		execute	shpt.Batch#Create @id=@batchID out, @siteID=@siteID, @errorCnt=@errorCnt, @errors=@errors;

		insert	shpt._Parcel
		(		ID,       BatchID,  RouteID,   LastMilerID,  SvcType, SvcZone, SvcClass,  POA, Weight, RcvHubID,        ContractID)
		select	x.Master, @batchID, r.RouteID, r.CourierID,  t.ID,     1,      1,       r.POA, q.v3,   isnull(h.ID, 0), c.ID
		from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default) x 
		cross	apply tvp.Quad#Of(x.House, default)                  q
		cross	apply core.Party#Type()                              e
		left	join  core.Party#Raw()                               h on h.Alias=q.v4 and h.Type=e.ZebraHub
		cross	apply tms.SvcType#For(cast(q.v2 as int), cast(q.v1 as int)) t
		cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)          r
		cross	apply acct.Contract#For(cast(q.v1 as int), @source)  c;

		--4.	Enqueue
		declare	@toSource  tinyint=(select InfoPath  from core.Source#ID())
		,		@queueType tinyint=(select BrokerApi from core.Queue#Type());
		insert	core._OutboundQ
			    (ToSource,  QueueType, MatterID,   StateID)
		select	@toSource, @queueType, MatterID, ToStateID
		from	@spec;

		-- 5.	Precourier Concern
		execute	shpt.PreCourier#ConcernBlock @index=3, @slip=@slip;

		-- 6.	Result:
		with cteResult(text) as
		(

			select	[text()]=concat(k.Many, c.Number, k.Duad, m.Number)
			from	tvp.Spr#Const() k, @idSeqs x
			cross	apply core.RefNbr#Type()   t
			join	core.RefNbr#Raw() m on m.MatterID=x.ID and m.Type=t.MIT
			join	core.RefNbr#Raw() c on c.MatterID=x.ID and c.Type=t.ClientRef
			for		xml path(N'')
		)
		select	@result=r.Tvp 
		from	cteResult 
		cross	apply tvp.Spr#Purify(text, default)  x
		cross	apply tvp.Pair#Make(@batchID, x.Tvp) r
		;
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
