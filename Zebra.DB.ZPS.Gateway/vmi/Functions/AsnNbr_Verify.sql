--Smile
CREATE FUNCTION [vmi].[AsnNbr$Verify](@siteID int, @asnNbrs nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=iif(r.MatterID is null, -1, isnull(b.ID, 0)), AsnNbr=x.Piece
	from	tvp.Many#Slice(@asnNbrs)       x
	cross	apply loc.RefNbr#Cast(x.Piece) n
	cross	apply core.RefNbr#Type()       k
	cross	apply core.State#ID()          s
	left	join core.RefNbr#Raw()         r on r.Number=n.Number and r.Type=k.AsnNbr
	left	join whse.StockInOrder#Base()  b on b.ID=r.MatterID  and 
												b.StateID=s.AsnNbrGenerated and
												b.SiteID=@siteID

)
