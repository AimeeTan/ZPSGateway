-- Smile
CREATE FUNCTION [vmi].[StockInOrder$Summary]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID, CreatedOn=PostedOn, Stage, r.Number, SiteID
	from	whse.StockInOrder#Base() x
	cross	apply core.RefNbr#Type() t
	join	core.RefNbr#Raw()        r on r.MatterID=x.ID and r.Type=t.AsnNbr
)