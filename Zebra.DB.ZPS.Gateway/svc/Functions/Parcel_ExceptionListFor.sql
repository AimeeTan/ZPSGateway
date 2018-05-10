--Ken, Aimee
CREATE FUNCTION [svc].[Parcel$ExceptionListFor](@siteID int)
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	x.ID, x.RefInfos, RefNbrs, Stage, StateID, StatedOn
	from	shpt.Parcel#Base()    x
	cross	apply core.Stage#ID() s
	where	x.Stage in (s.PreInterventionNeeded, s.InterventionNeeded, s.PostInterventionNeeded)
	and		x.SiteID=@siteID 
)