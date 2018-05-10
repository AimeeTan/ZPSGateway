/*
@slip    = at.Tvp.Block.Join(IDInfo, ShprInof, CneeInfo, DeclaredInfo:Mucho[GoodsInfo])
@context = at.Quad.Join(SvcType)
*/
--PeterHo
CREATE PROCEDURE [zeb].[Parcel$InitForZeb](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
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

		declare	@source E8,    @poa char(3), @svcType I32,  @routeID I32,       @courierID I32,         @stateID I32;
		select	@source=s.ZEB, @poa=r.POA,   @svcType=t.ID, @routeID=r.RouteID, @courierID=r.CourierID, @stateID=t.InitStateID
		from	tms.SvcType#For(cast(@context as int), @siteID) t
		cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA) r
		cross	apply core.Source#ID() s;

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
		declare	@idInfo E8,       @shprInfo E8,         @cneeInfo E8,         @declaredInfo E8;
		select	@idInfo=i.IDInfo, @shprInfo=i.ShprInfo, @cneeInfo=i.CneeInfo, @declaredInfo=i.DeclaredInfo 
		from	core.RefInfo#Type() i

		execute	core.RefNbr#AddMIC    @idSeqs=@idSeqs,   @source=@source,     @type=@type;
		execute	core.RefInfo#AddBlock @index=1, @idSeqs=@idSeqs, @slip=@slip, @type=@idInfo;
		execute	core.RefInfo#AddBlock @index=2, @idSeqs=@idSeqs, @slip=@slip, @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=3, @idSeqs=@idSeqs, @slip=@slip, @type=@cneeInfo;
		execute	core.RefInfo#AddBlock @index=4, @idSeqs=@idSeqs, @slip=@slip, @type=@declaredInfo;

		declare	@contractID I32=(select ID from acct.Contract#For(@siteID, @source));
		insert	shpt._Parcel
		(		ID, BatchID,  RouteID,  LastMilerID,  SvcType, SvcZone, SvcClass,  POA,  ContractID)
		select	ID, 0,       @routeID, @courierID,   @svcType, 1,       1,        @poa, @contractID
		from	@idSeqs;

		-- 4.	Result:
		select	@result=(select Tvp from tvp.I64Seqs#Join(@idSeqs));

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
