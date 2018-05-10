/*
	@slip    = Block[Comma<AddedSackMftID>, Comma<RemovedSackMftID>]
	@context = Flight
*/
-- AaronLiu
CREATE PROCEDURE [svc].[Flight$Assign](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		with cteSlip as
		(
			select	s.ID, FlightID=cast(@context as bigint)
			from	tvp.Block#At(1, @slip, default, default) x
			cross	apply tvp.I64#Slice(x.Tvp)				 s
			union	all
			select	s.ID, FlightID=0
			from	tvp.Block#At(2, @slip, default, default) x
			cross	apply tvp.I64#Slice(x.Tvp)				 s
		), cteMatter as
		(
			select	m.ID, m.PID, x.FlightID
			from	cteSlip x
			join	core.Matter#Raw() m on x.ID=m.ID
		)
		update	cteMatter set PID=FlightID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END