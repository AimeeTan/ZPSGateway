/*
	@slip = Duad<mawbNbr, FileBankID>
*/
-- Aimee
CREATE PROCEDURE [xpd].[SackMft$UploadLabelForXpd](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;
			declare	@siteID I32=(select SiteID from loc.Tenancy#Of(@tenancy));
			with cte as
			(
				select	RegID=k.Matter, RowID=cast(x.v1 as bigint), AuxID=31, FileBankID=x.v2, PosterID=@siteID -- HACK
				from	tvp.Duad#Slice(@slip, default, default) x
				cross	apply core.Attachment#Type()            t
				cross	apply core.Registry#ID()                k
			)
			merge	core._Attachment as o using cte as n
			on		(o.RegID=n.RegID and o.RowID=n.RowID and o.AuxID=n.AuxID and o.PosterID=n.PosterID)
			when	matched then update set FileBankID=n.FileBankID
			when	not matched then 
					insert(  RegID,   RowID,   AuxID,   PosterID,   FileBankID, PostedOn)
					values(n.RegID, n.RowID, n.AuxID, n.PosterID, n.FileBankID, getutcdate())
					;
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END