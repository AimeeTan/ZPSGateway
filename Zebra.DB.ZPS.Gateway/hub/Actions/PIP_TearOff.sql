/*
	@slip = Comma<PIPID>
*/
-- AaronLiu
CREATE PROCEDURE [hub].[PIP$TearOff](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@actionID E32=(select TearOff=11400 from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@slip, @actionID=@actionID, @tenancy=@tenancy, @beAffected=1;

		with	cte as
		(
			select	m.ID, m.PID
			from	tvp.I64#Slice(@slip) x
			join	core.Matter#Raw()	 m on x.ID=m.PID
		)
		update	cte set PID=0;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END