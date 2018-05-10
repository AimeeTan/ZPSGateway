-- AaronLiu
CREATE FUNCTION [zeb].[Parcel$ScanOne](@number varchar(40))
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Number, MatterID, Type, Stage
	from	core.RefNbr#ScanOne(@number, default, default)
)