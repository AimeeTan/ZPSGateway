-- Daxia
CREATE FUNCTION svc.Parcel$Label()
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	ID, PID, AID, Source, PostedOn,    x.Stage,      StateID,  StatedOn
	,		BatchID, BatchedOn,   RcvHubID,    RcvHubAlias,  SiteID,   SiteAlias
	,		RouteID, RouteCode,   x.CourierID, CourierAlias, BrokerID, BrokerAlias
	,		x.POA,   SvcType,     SvcZone,     SvcClass,     Weight,   Length, Width, Height
	,		RefNbrs, RefInfos,    Ledgers,     Challenges,   AddOnServices,    ZoneCode
	,		FacilityID=isnull(FacilityID%100, 0), BarcodeNbr
	from	svc.Parcel$Detail() x
	cross	apply core.RefNbr#Type() k
	left	join core.RefNbr#Raw() r on r.MatterID=x.ID and r.Type=k.PostCourier
	outer	apply tms.SvcFacility#For(x.Source, x.SvcClass, left(x.ZoneCode, 3)) f
	outer	apply tms.BarcodeNbr#Make(x.ZoneCode, r.Number)      b
)