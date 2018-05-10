/*
@slip = ContactID
*/
--AaronLiu
CREATE PROCEDURE [svc].[Contact$DefaultTo](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@siteID I32;
		select	@siteID=SiteID
		from	loc.Tenancy#Of(@tenancy);

		with	cte as
		(
			select	c.ID, c.IsDefault
			from	core.Contact#Raw() x, core.Contact#Raw() c
			where	x.ID=@slip and x.Type=c.Type and c.PartyID=@siteID
		)
		update	cte set IsDefault=0;
		update	core._Contact set IsDefault=1 where ID=@slip;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END