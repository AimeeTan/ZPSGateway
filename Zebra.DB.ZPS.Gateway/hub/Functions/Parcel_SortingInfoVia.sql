-- Eva
CREATE FUNCTION [hub].[Parcel$SortingInfoVia](@number varchar(40))
RETURNS TABLE
WITH SCHEMABINDING
--, ENCRYPTION
AS RETURN 
(
	select	ID, p.Stage, StateID, StatedOn, RefNbrs, Port=POA--?
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	shpt.Parcel#Base() p on p.ID=x.MatterID
)