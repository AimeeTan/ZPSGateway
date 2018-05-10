--PeterHo
CREATE FUNCTION [svc].[BizUnit$Lookup]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	Level, ID, PID, Type,  Source, Alias
	from	core.Party#Type()      k
	,		core.Party#PNodeDn(1)  x -- 1: Zebra HQ
	where	x.Type in (k.ZebraDiv, k.ZebraDept)
)