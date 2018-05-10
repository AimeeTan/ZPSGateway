/*
	@slip = Comma<PostCourierNbr>
*/
-- AaronLiu
CREATE PROCEDURE [svc].[Parcel$CfmDoorDeliverd](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		with cte(text) as
		(
			select	[text()]=concat(N',',  n.MatterID)
			from	tvp.Comma#Slice(@slip) x
			cross	apply core.Stage#ID()  s
			cross	apply core.RefNbr#ScanOne(x.Piece, s.Surrendered, s.DoorDelivered) n
			  for	xml path(N'')
		)
		select	@slip=Tvp from cte cross apply tvp.Spr#Purify(text, 1);

--		declare	@actionID I32=(select CfmDoorDelivered from core.Action#ID());
		declare	@actionID I32=19990;
		execute	svc.Parcel$Transit @idsInCsv=@slip, @actionID=@actionID, @tenancy=@tenancy;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END