-- Smile
CREATE FUNCTION [hub].[Parcel$CheckForRackIn](@number varchar(40))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN 
(
	select	p.ID
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	shpt.Parcel#Base() p on p.ID=x.MatterID
	cross	apply core.State#ID() k
	where	p.StateID=k.Carted
)