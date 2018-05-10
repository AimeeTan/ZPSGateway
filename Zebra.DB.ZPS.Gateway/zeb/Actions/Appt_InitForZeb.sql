/*
	NOTE: Just for hold batch parcel, nothing else.
*/
-- AaronLiu
CREATE PROCEDURE [zeb].[Appt$InitForZeb](@slip tvp, @tenancy tvp, @result tvp out)
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
		from	dbo.Nbr#Emit(1);

		declare	@source   E8=(select ZEB				from core.Source#ID())
		,		@type     E8=(select Appointment		from core.Matter#Type())
		,		@stateID I32=(select ApptReceived=26010 from core.State#ID())    -- Todo: Refine
		declare	@stage   E32=(select Stage				from core.Stage#Of(@stateID));
		insert	core._Matter
		(		ID, PosterID, StateID,  Stage,  Source,  Type, PostedOn   )
		select	ID, @siteID, @stateID, @stage, @source, @type, getutcdate()
		from	@idSeqs;

		-- 2.	Result:
		select	@result=(select Tvp from tvp.I64Seqs#Join(@idSeqs));

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END