/*
	@slip    = Comma<ParcelID>
*/
-- AaronLiu
CREATE PROCEDURE [zeb].[Parcel$Reset](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		with	cte as
		(
			select	m.ID, m.AID
			from	tvp.I64#Slice(@slip) x
			join	core.Matter#Raw()	 m on x.ID=m.ID
		)
		update	cte set AID=0;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH 
END