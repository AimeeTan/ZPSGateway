-- Daxia
CREATE FUNCTION [core].[Hub#ByPOA](@poa char(3))
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID, PID, AID, Type, Source, Alias
	from	core.Party#Raw() x
	cross	apply core.Party#Type() t
	where	x.Type=t.ZebraHub and x.Alias=@poa
)