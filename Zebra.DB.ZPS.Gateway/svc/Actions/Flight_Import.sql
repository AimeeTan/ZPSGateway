/*
	@slip = Many[Tuplet<POD, POA, AirlineID, FlightNbr, ETD, ETA>];
*/
-- AaronLiu
CREATE PROCEDURE [svc].[Flight$Import](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @site I32;
		select	@userID=UserID, @site=SiteID
		from	loc.Tenancy#Of(@tenancy);

		declare	@now        DT=getutcdate()
		,		@type       E8=(select Flight       from core.Matter#Type())
		,		@stage      E32=(select InfoImported from core.Stage#ID())
		,		@source     E8=(select InfoPath     from core.Source#ID())
		,		@stateID   I32=(select FlightBooked from core.State#ID())
		;

		declare	@idSeqs I64Seqs; 
		insert	@idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Many@Count(@slip));

		insert	core._Matter
		(		ID, PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		select	ID,    @site, @stateID, @stage, @source, @type,     @now
		from	@idSeqs;

		with cteFlight as
		(
			select	Seq, POD=v1, POA=v2, AirlineID=cast(v3 as bigint), FlightNbr=v4
			,		ETD=cast(isnull(nullif(v5, ''), '0001') as datetime2(2))
			,		ETA=cast(isnull(nullif(v6, ''), '0001') as datetime2(2))
			from	tvp.Tuplet#Slice(@slip, default, default)
		)
		insert	tms._Flight
		(		ID, POD, ETD, POA, ETA, FlightNbr, AirlineID)
		select	ID, POD, ETD, POA, ETA, FlightNbr, AirlineID
		from	cteFlight x
		join	@idSeqs   m on x.Seq=m.Seq;

		insert	core._Activity
		(		MatterID,  StateID,  UserID, TalliedOn)
		select	ID,		  @stateID, @userID,      @now
		from	@idSeqs;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END