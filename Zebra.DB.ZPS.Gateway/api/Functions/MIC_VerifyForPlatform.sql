/*
@micsInCsv =Duad[Alias, MIC]
*/
--Smile, AaronLiu
CREATE	FUNCTION [api].[MIC$VefityForPlatform](@userID int, @micsInCsv nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=isnull(b.ID, 0), ClientRefNbr=d.Number
	from	tvp.Duad#Slice(@micsInCsv, default, default) x
	cross	apply loc.RefNbr#Cast(x.v2)                  d
	cross	apply core.RefNbr#Type()                     k
	left	join  core.RefNbr#Raw()                      r on r.Number=d.Number and r.Type=k.MIT
	join	core.Party#Raw()                             n on n.ID=@userID
	left	join  core.Party#Raw()                       p on p.Source=n.Source and p.Alias=x.v1
	cross	apply core.Stage#ID()                        s
	left	join  core.Matter#Raw()                      b on r.MatterID=b.ID   and b.PosterID=p.ID
)
