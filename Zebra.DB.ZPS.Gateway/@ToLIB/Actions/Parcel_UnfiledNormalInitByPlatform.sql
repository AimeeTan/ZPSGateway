/*
@slip    =Entry[Block< Tuplet<SiteID, SvcType, Weight, RchHubAlias, POA>
			, RefNbr
			, PreCourier
			, ShprInfo
			, CneeInfo
			, Mucho[LineInfo]
			, IDInfo
			, AddOnSvcInfo>]
@context = batchID
*/
--Smile
CREATE PROCEDURE [shpt].[Parcel#UnfiledNormalInitByPlatform](@slip tvp, @context tvp, @tenancy tvp)
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
		cross	apply tvp.Tuplet#Of(x.House, default)                        q
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
		execute	core.RefNbr#AddBlock  @index=3, @idSeqs=@idSeqs, @slip=@slip, @type=@preCourier;
		execute	core.RefInfo#AddBlock @index=4, @idSeqs=@idSeqs, @slip=@slip, @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=5, @idSeqs=@idSeqs, @slip=@slip, @type=@cneeInfo;
		execute	core.RefInfo#AddBlock @index=6, @idSeqs=@idSeqs, @slip=@slip, @type=@declaredInfo;
		execute	core.RefInfo#AddBlock @index=7, @idSeqs=@idSeqs, @slip=@slip, @type=@IDInfo;
		execute	core.RefInfo#AddBlock @index=8, @idSeqs=@idSeqs, @slip=@slip, @type=@addOnSvcInfo;

		insert	into core._RefInfo(MatterID, Type, Info)
		select	x.Master, @brokerageInfo, b.BrokerageInfo
		from	tvp.Block#FoldT(6, @idSeqs, @slip, default, default) x
		cross	apply loc.Declared$ToBrokerage(x.House, default)	 b
		;
		
		-- 3.	Add Batch & Parcels:
		declare	@batchID I64=(@context);
		insert	shpt._Parcel
		(		ID, BatchID, RouteID, LastMilerID, SvcType, SvcZone, SvcClass,
				POA, Weight, RcvHubID, ContractID)
		select	x.Master, @batchID, isnull(d.RouteID, r.RouteID), r.CourierID, t.ID, 1, 1, 
				iif(nullif(q.v5, '') is null, r.POA, q.v5), q.v3, isnull(h.ID, 0), c.ID
		from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default) x 
		cross	apply tvp.Tuplet#Of(x.House, default)                  q
		cross	apply core.Party#Type()                              e
		left	join  core.Party#Raw()                               h on h.Alias=q.v4 and h.Type=e.ZebraHub
		cross	apply tms.SvcType#For(cast(q.v2 as int), cast(q.v1 as int)) t
		outer	apply tms.SvcRoute#For(t.ID, cast(q.v5 as char(3)))  d
		cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)          r
		cross	apply acct.Contract#For(cast(q.v1 as int), @source)  c;
		
		-- 4.	Precourier Concern
		execute	shpt.PreCourier#ConcernBlock @index=3, @slip=@slip;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
