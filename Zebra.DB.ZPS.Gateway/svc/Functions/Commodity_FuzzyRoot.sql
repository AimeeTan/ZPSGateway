--Daxia
CREATE FUNCTION [svc].[Commodity$FuzzyRoot](@svcType int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	c.ID, c.PID, Path
	,		Surcharge,   DutyID, DutyRate, DutyCode
	from	tms.SvcType#Raw()    x
	cross	apply svc.Commodity$Root(x.CmdyRootID) c
	where	x.ID=@svcType
)
