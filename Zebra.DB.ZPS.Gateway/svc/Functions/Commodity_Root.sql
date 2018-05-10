--PeterHo
CREATE FUNCTION [svc].[Commodity$Root](@cmdyRootID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	c.ID, c.PID, [Path]=c.Name
	,		c.Surcharge, c.DutyID, c.DutyRate, c.DutyCode
	from	brkg.Commodity#Raw()   x
	join	brkg.Commodity#Deep()  c on c.PID=x.ID
	where	x.PID=0 and x.ID=@cmdyRootID
)
