-- AaronLiu
CREATE FUNCTION [hub].[Parcel$ScanOneForTearOff](@number varchar(40))
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID=MatterID, Type, Stage
	from	core.RefNbr#ScanOne(@number, default, default)
)