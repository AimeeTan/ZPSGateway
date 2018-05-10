/*
@slip    = Entry[Block<PreCourier, HandWrittenOrderImg>]
@context = Duad<Source, SiteID>
@result  = Pair<BatchID, Comma[ParcelID]>
*/
--Daxia
CREATE PROCEDURE [api].[Parcel$InitForHandWrittenOrder](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- 0.	Tenancy & Contexts:
		declare	@userID I32=(select UserID from loc.Tenancy#Of(@tenancy));
		
		declare	@source E8, @siteID I32;
		select	@source=v1, @siteID=cast(v2 as int)
		from	tvp.Duad#Of(@context, default);

		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		declare	@type    E8 =(select Parcel from core.Matter#Type());
		declare	@stateID I32=(select InfoPictureReceived from core.State#ID());
		declare	@stage   E32=(select PreInterventionNeeded from core.Stage#ID());
		insert	core._Matter
		(		ID,  PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		select	ID,  @siteID,  @stateID, @stage, @source, @type, getutcdate()
		from	@idSeqs;

		execute	core.Activity#AddByIdSeqs @idSeqs=@idSeqs, @stateID=@stateID, @userID=@userID;

		-- 2.	Add RefNbrs & RefInfos:
		declare	@preCourier E8,           @handWrittenOrderImgInfo E8;
		select	@preCourier=n.PreCourier, @handWrittenOrderImgInfo=25
		from	core.RefNbr#Type() n,   core.RefInfo#Type() i

		execute	core.RefNbr#AddMIC       @idSeqs=@idSeqs, @source=@source,  @type=@type;

		execute	core.RefNbr#AddBlock  @index=1, @idSeqs=@idSeqs, @slip=@slip, @type=@preCourier;
		execute	core.RefInfo#AddBlock @index=2, @idSeqs=@idSeqs, @slip=@slip, @type=@handWrittenOrderImgInfo;

		-- 3.	Add Batch & Parcels:
		declare	@batchID I64;
		execute	shpt.Batch#Create @id=@batchID out, @siteID=@siteID, @errorCnt=0, @errors=N'';

		declare	@routeID I32=0, @courierID I32=0, @contractID I32=0, @poa char(3)=N'';
		insert	shpt._Parcel
		(		ID,  BatchID,  RouteID, LastMilerID,  SvcType, SvcZone, SvcClass,  POA,  ContractID)
		select	ID, @batchID, @routeID, @courierID,   0,	   1,       1,        @poa, @contractID
		from	@idSeqs;

		-- 4.	Precourier Concern
		execute	shpt.PreCourier#ConcernBlock @index=1, @slip=@slip;

		-- 5.	Result:
		with cteResult(text) as
		(
			select	[text()]=concat(N',', x.ID)
			from	@idSeqs x
			for		xml path(N'')
		)
		select	@result=r.Tvp 
		from	cteResult 
		cross	apply tvp.Spr#Purify(text, 1) x
		cross	apply tvp.Pair#Make(@batchID, x.Tvp) r
		;
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
