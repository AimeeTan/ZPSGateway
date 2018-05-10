--Aimee
CREATE FUNCTION [svc].[Parcel$VerifyForEMS](@micInCsv nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.MIC, LastMilerID=isnull(p.LastMilerID,0) 
	from	svc.MIC$Vefity(@micInCsv) x
	left	join shpt.Parcel#Raw()    p on p.ID=x.ID
)