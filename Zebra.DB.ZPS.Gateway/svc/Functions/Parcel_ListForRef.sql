-- Daxia
Create FUNCTION [svc].[Parcel$ListForRef](@siteID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, RefNbrs, RefInfos, Stage
	from	shpt.Parcel#Base()
	where	SiteID=@siteID
)