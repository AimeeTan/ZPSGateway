--PeterHo
CREATE	FUNCTION [svc].[MIC$Vefity](@micsInCsv nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID=isnull(r.MatterID,0), MIC=x.Number
	from	loc.RefNbr#Slice(@micsInCsv) x
	cross	apply core.RefNbr#Type() k
	left	join  core.RefNbr#Raw()  r on r.Number=x.Number and r.Type=k.MIT
)
