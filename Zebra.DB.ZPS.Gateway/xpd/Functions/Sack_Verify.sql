--	Aimee
CREATE	FUNCTION [xpd].[Sack$Verify](@numbersInCsv nvarchar(max), @siteID int)
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=isnull(m.ID,0), SackNbr=x.Number
	from	loc.RefNbr#Slice(@numbersInCsv) x
	join	core.RefNbr#Raw()  r on r.Number=x.Number
	join	core.Matter#Raw()  m on m.ID=r.MatterID
	where	m.PosterID=@siteID
)