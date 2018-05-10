--Aimee, Smile
CREATE FUNCTION [svc].[Parcel$RefInfoFor](@number varchar(40))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, m.Stage, SiteAlias, RefInfos, RefNbrs
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	shpt.Parcel#Base() m on m.ID = x.MatterID
)
