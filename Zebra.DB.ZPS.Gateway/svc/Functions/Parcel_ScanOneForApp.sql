-- AaronLiu
CREATE FUNCTION [svc].[Parcel$ScanOneForApp](@number varchar(40))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	p.ID, p.Stage
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	shpt.Parcel#Base() p on p.ID=x.MatterID
)