/*
@slip    = Entry[Block<PickupInfo, PickupOn, EstWeight>]
@context = Source
*/
--AaronLiu
CREATE PROCEDURE [svc].[Appointment$Init](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- 0.	Tenancy & Contexts:
		declare	@siteID I32,    @userID I32
		select	@siteID=SiteID, @userID=UserID
		from	loc.Tenancy#Of(@tenancy) x

		-- 1.	Add Matters & Activities:
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		declare	@stateID E32=(select AppointmentInit=17271	from core.State#ID());	--HACK
		declare	@type	  E8=(select Appointment			from core.Matter#Type())
		,		@stage	 E32=(select Stage					from core.Stage#Of(@stateID));
		insert	core._Matter
		(		ID,  PosterID,  StateID,  Stage,  Source,  Type,  PostedOn   )
		select	ID,  @siteID,  @stateID, @stage, @context, @type, getutcdate()
		from	@idSeqs;

		execute	core.Activity#AddByIdSeqs @idSeqs=@idSeqs, @stateID=@stateID, @userID=@userID;

		-- 2.	Add RefInfos:
		declare	@pickupInfo E8=(select PickupInfo from core.RefInfo#Type());
		execute	core.RefInfo#AddBlock @index=1, @idSeqs=@idSeqs, @slip=@slip, @type=@pickupInfo;

		-- 3.	Add Appointments:
		insert	shpt._Appointment
		(		ID, PickupOn, EstWeight)
		select	ID, t.v2,	  t.v3
		from	@idSeqs x
		cross	apply tvp.Spr#Const() k
		cross	apply tvp.Triad#Slice(@slip, k.Block, k.Entry) t
		where	x.Seq=t.Seq

		-- 4.	Result:
		select	@result=(select Tvp from tvp.I64Seqs#Join(@idSeqs));

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END