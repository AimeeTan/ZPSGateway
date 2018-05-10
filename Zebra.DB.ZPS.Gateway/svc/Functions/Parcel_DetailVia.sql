-- Eason, Aimee, AaronLiu
CREATE FUNCTION svc.Parcel$DetailVia(@number varchar(40))
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	ID, PID,     AID,		p.Source,  PostedOn,	p.Stage, StateID, StatedOn
	,		BatchID,     BatchedOn, RcvHubID,  RcvHubAlias, RcvHubUtcOffset,  SiteID
	,		SiteAlias,   RouteID,	RouteCode, CourierID,   CourierAlias,	  BrokerID
	,		BrokerAlias, POA,		SvcType,   SvcZone,		SvcClass,		  Weight
	,		Length,		 Width,		Height,	   RefNbrs,		RefInfos,		  Ledgers
	,		Challenges,  ZoneCode,  AddOnServices		  
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	svc.Parcel$Detail() p on p.ID=x.MatterID
)