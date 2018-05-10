/*
@slip		= Entry[Block<RefNbr, PreCourier, Shipper, Consignee, Mucho[LineInfo], CneeIdNbr.IDNbr, GrossWeight.G, RemarkInfo>]
 RemarkInfo = Quad<Remark1, Remark2, Remark3, Remark4>
@context	= Quad<Source, SvcType, errorCnt, errors>
*/
--Smile, AaronLiu
CREATE PROCEDURE [app].[Parcel$InitForEship](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- 0.	Tenancy & Contexts:
		declare	@siteID I32,    @userID I32,    @tenantSource E8;
		select	@siteID=SiteID, @userID=UserID, @tenantSource=p.Source
		from	loc.Tenancy#Of(@tenancy) x
		join	core.Party#Raw() p on p.ID=x.SiteID;

		declare	@source E8, @errorCnt int, @errors json, @poa char(3), @svcType I32,  @routeID I32,       @courierID I32,         @stateID I32,           @contractID I32;
		select	@source=v1, @errorCnt=v3,  @errors=v4,   @poa=r.POA,   @svcType=t.ID, @routeID=r.RouteID, @courierID=r.CourierID, @stateID=t.InitStateID, @contractID=c.ID
		from	tvp.Quad#Of(@context, default)                          x
		cross	apply tms.SvcType#For(cast(x.v2 as int), @siteID)       t
		cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)             r
		cross	apply acct.Contract#For(@siteID, @tenantSource) c;  --HACK
		

		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		declare	@type  E8=(select Parcel from core.Matter#Type())
		,		@stage E32=(select Stage  from core.Stage#Of(@stateID));
		insert	core._Matter
		(		ID,  PosterID,  StateID,  Stage,  Source,  Type, PostedOn   )
		select	ID,  @siteID,  @stateID, @stage, @source, @type, getutcdate()
		from	@idSeqs;

		execute	core.Activity#AddByIdSeqs @idSeqs=@idSeqs, @stateID=@stateID, @userID=@userID;

		-- 2.	Add RefNbrs & RefInfos:
		declare	@clientRef	  E8, @shprInfo E8, @cneeInfo   E8
		,		@declaredInfo E8, @IDInfo   E8, @preCourier E8
		,		@remarkInfo	  E8
		;
		select	@clientRef=n.ClientRef,		  @shprInfo=i.ShprInfo, @cneeInfo=i.CneeInfo
		,		@declaredInfo=i.DeclaredInfo, @IDInfo=i.IDInfo,		@preCourier=n.PreCourier
		,		@remarkInfo=i.RemarkInfo
		from	core.RefNbr#Type() n, core.RefInfo#Type() i
		
		execute	core.RefNbr#AddMIC @idSeqs=@idSeqs, @source=@source, @type=@type;

		execute	core.RefNbr#AddBlock  @index=1, @idSeqs=@idSeqs, @slip=@slip, @type=@clientRef;
		execute	core.RefNbr#AddBlock  @index=2, @idSeqs=@idSeqs, @slip=@slip, @type=@preCourier;
		execute	core.RefInfo#AddBlock @index=3, @idSeqs=@idSeqs, @slip=@slip, @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=4, @idSeqs=@idSeqs, @slip=@slip, @type=@cneeInfo;
		execute	core.RefInfo#AddBlock @index=5, @idSeqs=@idSeqs, @slip=@slip, @type=@declaredInfo;
		execute	core.RefInfo#AddBlock @index=6, @idSeqs=@idSeqs, @slip=@slip, @type=@IDInfo;
		execute	core.RefInfo#AddBlock @index=8, @idSeqs=@idSeqs, @slip=@slip, @type=@remarkInfo;

		-- 3.	Add Batch & Parcels:
		declare	@batchID I64;
		execute	shpt.Batch#Create @id=@batchID out, @siteID=@siteID, @errorCnt=@errorCnt, @errors=@errors;

		insert	shpt._Parcel
		(		ID,  BatchID,  RouteID,  LastMilerID, SvcType, SvcZone, SvcClass,  POA, Weight,  ContractID)
		select	ID, @batchID, @routeID, @courierID,  @svcType, 1,       1,        @poa, v.Piece, @contractID
		from	@idSeqs x
		join	tvp.Pcs#SliceV(/*index*/7, @slip, default, default) v on v.Seq=x.Seq;

		-- 4.	Precourier Concern
		execute	shpt.PreCourier#ConcernBlock @index=2, @slip=@slip;
		execute shpt.Concern#AttachPreCheckTo @idSeqs=@idSeqs;
		-- 5.	Result:
		select	@result=@batchID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END