/*
	@slip = Entry<Block[Comma<ParcelIDs>, ShprInfo, CneeInfo]>
	NOTE: PIP = Parcel in Parcel.
*/
-- AaronLiu
CREATE PROCEDURE [zeb].[PIP$InitForZeb](@slip tvp, @tenancy tvp, @result tvp out)
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

		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		declare	@source   E8=(select ZEB			  from core.Source#ID())
		,		@type     E8=(select PIP			  from core.Matter#Type())
		,		@stateID I32=(select PIPCreated=27010 from core.State#ID()) -- Todo: Add 27010 To core.State#ID()
		declare	@stage   E32=(select Stage			  from core.Stage#Of(@stateID));
		insert	core._Matter
		(		ID, PosterID,  StateID,  Stage,  Source,  Type, PostedOn   )
		select	ID,  @siteID, @stateID, @stage, @source, @type, getutcdate()
		from	@idSeqs;

		execute	core.Activity#AddByIdSeqs @idSeqs=@idSeqs, @stateID=@stateID, @userID=@userID;

		-- 2.	Add RefNbrs & RefInfos:
		declare	@shprInfo E8=(select ShprInfo from core.RefInfo#Type())
		,		@ceeeInfo E8=(select CneeInfo from core.RefInfo#Type())
		;
		execute	core.RefNbr#AddMIC				@idSeqs=@idSeqs, @source=@source, @type=@type;
		execute	core.RefInfo#AddBlock @index=2, @idSeqs=@idSeqs, @slip=@slip,	  @type=@shprInfo;
		execute	core.RefInfo#AddBlock @index=3, @idSeqs=@idSeqs, @slip=@slip,	  @type=@ceeeInfo;

		-- 3.	Move Parcel Into PIP
		with	cte as
		(
			select	m.ID, m.AID, NewAID=x.Master
			from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default) x
			cross	apply tvp.I64#Slice(x.House) h
			join	core.Matter#Raw()			 m on h.ID=m.ID
		)
		update	cte set AID=NewAID;

		declare	@contractID I32=(select ID from acct.Contract#For(@siteID, @source));
		insert	shpt._Parcel
		(		ID, BatchID, RouteID, LastMilerID, SvcType, SvcZone, SvcClass, POA,  ContractID)
		select	ID, 0,       0,		  0,		   0,		1,       1,        N'', @contractID
		from	@idSeqs;

		-- 3.	Result:
		select	@result=(select Tvp from tvp.I64Seqs#Join(@idSeqs));

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END