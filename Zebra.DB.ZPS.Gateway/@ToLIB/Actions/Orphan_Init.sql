-- AaronLiu
CREATE PROCEDURE [shpt].[Orphan#Init](@numbersInCsv tvp, @tenancy tvp, @matterID I64 out, @number tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32,	@siteID I32;
		select	@userID=UserID, @roleID=RoleID, @siteID=SiteID
		from	loc.Tenancy#Of(@tenancy);

		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(1);

		declare	@stateID  I32=(select OrphanCreated from core.State#ID());
		declare	@source	  E8=(select InfoPath	   from core.Source#ID())
		,		@stage	  E32=(select Stage		   from core.Stage#Of(@stateID))
		,		@type	  E8=(select OrphanParcel  from core.Matter#Type());
		insert	core._Matter
		(		ID, PosterID,  StateID,  Stage,  Source,  Type, PostedOn   )
		select	ID, @siteID,  @stateID, @stage, @source, @type, getutcdate()
		from	@idSeqs;

		execute	core.Activity#AddByIdSeqs @idSeqs=@idSeqs, @stateID=@stateID, @userID=@userID;

		-- 2.	Add RefNbrs
		declare	@preCourierNbr loc.RefNbr
		,		@preCourier	   E8=(select PreCourier from core.RefNbr#Type());
		with	cte as
		(
			select	top 1 Number
			from	loc.RefNbr#Slice(@numbersInCsv)
			order	by len(Number) desc
		)
		select	@preCourierNbr=Number from cte

		execute	core.RefNbr#AddMIC			   @idSeqs=@idSeqs, @source=@source,	  @type=@type;
		execute	core.RefNbr#AddBlock @index=1, @idSeqs=@idSeqs, @slip=@preCourierNbr, @type=@preCourier;

		-- 3.	Add Batch & Parcels:
		insert	shpt._Parcel
		(		ID, BatchID, RouteID, LastMilerID, SvcType, SvcZone, SvcClass, POA, ContractID)
		select	ID, 0,		 0,		  0,		   0,		1,		 1,		   N'', 0
		from	@idSeqs;

		-- 4.	Result:
		select	@number=@preCourierNbr;
		select	@matterID=(select ID from @idSeqs);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END