-- Eason, AaronLiu, Smile, Daxia, Aimee
CREATE FUNCTION [svc].[Parcel$List]()
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	x.ID,    x.Source,  PostedOn,  Stage,     StateID,  StatedOn, BatchID,  RcvHubID
	,		SiteID, RouteID, RouteCode, CourierID, BrokerID, SvcType,  SvcZone,  SvcClass, CmdyRootID
	,		Weight, Length,  Width,     Height,    POA,      RefNbrs,  RefInfos, Ledgers,  Challenges
	,		LastMilerCode, HandlerID,   u.Handler, AddOnServices, HasIDNbr, HasConcern,    ZoneCode
	from	shpt.Parcel#Deep()                      x 
	cross	apply svc.User$ContactName(x.HandlerID) u	
	cross	apply core.Concern#Exists(x.ID)         e
	cross	apply shpt.IDNbr#Exists(x.ID)           i
)
