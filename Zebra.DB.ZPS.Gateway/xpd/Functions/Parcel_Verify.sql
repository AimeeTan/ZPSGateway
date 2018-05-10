--	Aimee
CREATE	FUNCTION [xpd].[Parcel$Verify](@micsInCsv nvarchar(max), @siteID int)
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=m.MatterID, x.Number, Stage
	from	loc.RefNbr#Slice(@micsInCsv)  x
	cross	apply core.MIC#IdOf(x.Number) m
	join	core.Matter#Raw()             r on r.ID=m.MatterID
	where	r.PosterID=@siteID
)