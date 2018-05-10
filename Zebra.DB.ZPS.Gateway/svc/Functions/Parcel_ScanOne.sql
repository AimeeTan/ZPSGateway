-- Eason
CREATE FUNCTION [svc].[Parcel$ScanOne](@number varchar(40))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	r.Number
	from	core.RefNbr#MatchOne(@number, 1, 25500) x 
	cross	apply core.RefNbr#Type()              t
	join	core.RefNbr#Raw()                     r on r.MatterID=x.MatterID and r.Type=t.MIT
	where	MatchedCnt=1
)