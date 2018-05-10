-- Eason, AaronLiu
CREATE FUNCTION svc.Parcel$Detail()
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	x.ID,	  PID, AID,	   x.Source, PostedOn,	  Stage, StateID, StatedOn
	,		BatchID,  BatchedOn,   RcvHubID, RcvHubAlias, RcvHubUtcOffset=t.UtcOffset
	,		SiteID,   SiteAlias,   RouteID,  RouteCode,   CourierID, CourierAlias
	,		BrokerID, BrokerAlias, POA,		 SvcType,     SvcZone,   SvcClass
	,		Weight,   Length,	   Width,	 Height,	  RefNbrs,	 RefInfos
	,		Ledgers,  Challenges,  ZoneCode, AddOnServices
	from	shpt.Parcel#Deep() x
	join	core.Tenant#Raw()  t on t.ID=x.RcvHubID
)