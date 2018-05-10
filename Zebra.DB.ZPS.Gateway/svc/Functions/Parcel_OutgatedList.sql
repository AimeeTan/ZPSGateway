--Smile, Aimee
CREATE FUNCTION [svc].[Parcel$OutgatedList]()
RETURNS TABLE 
WITH SCHEMABINDING, ENCRYPTION
AS RETURN 
(
	select	x.ID, x.Source, x.StatedOn,  x.StateID, SvcType, x.Stage, x.PostedOn, x.RefStamps, x.RefNbrs
	,		x.POA,  RcvHubID, RcvHubAlias, RouteID, RouteCode, LastMilerAlias,      MawbNbr,     FlightNbr
	,		[PosterAlias]=x.SiteAlias, [SackNbr]=s.RefNbrs,    RefInfos
	from	shpt.Parcel#Deep()       x	
	left	join shpt.Sack#Base()    s  on s.ID=x.PID
	left	join shpt.SackMft#Deep() sm on sm.ID=s.PID or sm.ID=x.PID
)

