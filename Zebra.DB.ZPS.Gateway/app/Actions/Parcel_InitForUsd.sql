/*
@slip    = at.Tvp.Block.Join(RefNbr, ShprInfo, CneeInfo
,          DeclaredInfo[Quad.Join(GoodsInfo, LineQty, LineTotal, CmdyID).Over(at.Tvp.Mucho)]
,          Weight, Height, Width, Length ).Over(at.Tvp.Entry)
@context = at.Quad.Join(Source, SvcType, errorCnt, errors)
*/
--Daxia
CREATE PROCEDURE [app].[Parcel$InitForUsd](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- 0.	Tenancy & Contexts:
		declare	@siteID I32,    @userID I32;
		select	@siteID=SiteID, @userID=UserID
		from	loc.Tenancy#Of(@tenancy);

		declare	@source E8, @errorCnt int, @errors json, @svcType I32,  @routeID I32,       @courierID I32,         @stateID I32,           @contractID I32;
		select	@source=v1, @errorCnt=v3,  @errors=v4,   @svcType=t.ID, @routeID=r.RouteID, @courierID=r.CourierID, @stateID=t.InitStateID, @contractID=c.ID
		from	tvp.Quad#Of(@context, default)                          x
		cross	apply tms.SvcType#For(cast(x.v2 as int), @siteID)       t
		cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)             r
		cross	apply acct.Contract#For(@siteID, cast(x.v1 as tinyint)) c;
		
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

		-- 2.1	Add RefNbrs & RefInfos:
		declare	@clientRef E8,          @postCourier E8,            @shprInfo E8,         @cneeInfo E8,         @declaredInfo E8,             @brkgInfo E8;
		select	@clientRef=n.ClientRef, @postCourier=n.PostCourier, @shprInfo=i.ShprInfo, @cneeInfo=i.CneeInfo, @declaredInfo=i.DeclaredInfo, @brkgInfo=i.BrokerageInfo
		from	core.RefNbr#Type() n,   core.RefInfo#Type() i

		execute	core.RefNbr#AddMIC       @idSeqs=@idSeqs, @source=@source,  @type=@type;

		execute	core.RefNbr#AddBlock  @index=1, @idSeqs=@idSeqs, @slip=@slip, @type=@clientRef;
		execute	core.RefInfo#AddBlock @index=2, @idSeqs=@idSeqs, @slip=@slip, @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=3, @idSeqs=@idSeqs, @slip=@slip, @type=@cneeInfo;
		execute	core.RefInfo#AddBlock @index=4, @idSeqs=@idSeqs, @slip=@slip, @type=@declaredInfo;
		execute	core.RefInfo#AddBlock @index=5, @idSeqs=@idSeqs, @slip=@slip, @type=@brkgInfo;
		
		-- 2.2	Prepare PicSpecs:
		declare	@picSpec tms.PicSpec; insert @picSpec
		(		MeasuredWt, SvcType, Zip3,           Plus2,                  RefNbr)
		select	f.v5,      @svcType, left(i.v11, 3), substring(i.v11, 4, 2), f.v1
		from	tvp.Field#Slice(@slip, N'	%	', default) f
		cross	apply tvp.Dozen#Of(f.v3, default)           i;

		-- 2.3	Emit PICs:
		declare	@picResult tms.PicResult; insert @picResult
		exec	tms.Pic#Emit @source=@source, @picSpec=@picSpec;
		
		declare	@postCourierSpec as table
		(
			MatterID    dbo.I64     NOT NULL,
			SvcClass    tinyint     NOT NULL,
			Type        dbo.E8      NOT NULL,--RefNbr Type
			PostCourier varchar(40) NOT NULL
		);
		declare	@svcClassLW     dbo.E8=13, @svcClassPS     dbo.E8=14
		,		@postCourierPre dbo.E8=18, @postCourierOrg dbo.E8=19
		;
		insert	@postCourierSpec
		(		MatterID,   SvcClass, PostCourier,   Type)
		select	    x.ID, r.SvcClass, t.TrackingNbr, iif(r.SvcClass=@svcClassLW, @postCourierPre, @postCourierOrg)
		from	@idSeqs x join @picResult r on r.SeqNbr=x.Seq
		cross	apply tms.TrackingNbr#Make(r.SvcCode, r.MailerID, r.MailerSeq, x.ID) t
		;
		-- 2.4	Init TrackingNbr
		insert	core._RefNbr
		(		MatterID, Type, Number)
		select	MatterID, Type, PostCourier
		from	@postCourierSpec;
		-- 2.5	Init PostCourier
		insert	core._RefNbr
		(		MatterID, Type,          Number)
		select	MatterID, n.PostCourier, x.PostCourier
		from	@postCourierSpec x cross apply core.RefNbr#Type() n;


		-- 3.1	Add Batch:
		declare	@batchID I64;
		execute	shpt.Batch#Create @id=@batchID out, @siteID=@siteID, @errorCnt=@errorCnt, @errors=@errors;

		
		-- 3.2	Add Parcels:
		declare @weight real, @length real, @width real, @height real;
		insert	shpt._Parcel
		(		ID,  BatchID,  RouteID, LastMilerID,  SvcType,  SvcZone,              SvcClass,   POA,  ContractID, Weight, Height, Width, Length, ZoneCode)
		select	ID, @batchID, @routeID, @courierID,  @svcType,  isnull(z.Zone, 1),  r.SvcClass, r.POA, @contractID, s.v5,   s.v6,   s.v7,  s.v8,   left(i.v11, 5)
		from	@idSeqs x join @picResult r on r.SeqNbr=x.Seq
		join	tvp.Field#Slice(@slip, N'	%	', default) s on s.Seq=x.Seq
		cross	apply tvp.Dozen#Of(s.v3, default)           i
		outer	apply tms.SvcZone#For(@source, r.SvcClass, r.OnZip3, left(i.v11, 3)) z;
		
		-- 5.	Result:
		--select	@result=@batchID;
		with cteResult(text) as
		(
			select	[text()]=concat(k.Many, c.Number, k.Duad, m.Number)
			from	tvp.Spr#Const() k, @idSeqs x
			cross	apply core.RefNbr#Type()   t
			join	core.RefNbr#Raw() m on m.MatterID=x.ID and m.Type=t.MIT
			join	core.RefNbr#Raw() c on c.MatterID=x.ID and c.Type=t.ClientRef
			for		xml path(N'')
		)
		select	@result=r.Tvp from cteResult 
		cross	apply tvp.Spr#Purify(text, default)  x
		cross	apply tvp.Pair#Make(@batchID, x.Tvp) r
		;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
