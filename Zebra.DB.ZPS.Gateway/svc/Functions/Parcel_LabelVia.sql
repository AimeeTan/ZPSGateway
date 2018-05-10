-- Daxia
CREATE FUNCTION svc.Parcel$LabelVia(@number varchar(40))
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	ID, PID, AID, Source, PostedOn,    p.Stage,      StateID,  StatedOn
	,		BatchID, BatchedOn,   RcvHubID,    RcvHubAlias,  SiteID,   SiteAlias
	,		RouteID, RouteCode,   p.CourierID, CourierAlias, BrokerID, BrokerAlias
	,		p.POA,   SvcType,     SvcZone,     SvcClass,     Weight,   Length, Width, Height
	,		RefNbrs, RefInfos,    Ledgers,     Challenges,   AddOnServices,    ZoneCode
	,		FacilityID=isnull(FacilityID%100, 0), BarcodeNbr
	from	core.RefNbr#ScanOne(@number, default, default) x
	cross	apply core.RefNbr#Type() k
	join	svc.Parcel$Detail() p on p.ID=x.MatterID
	left	join core.RefNbr#Raw() r on r.MatterID=x.MatterID and r.Type=k.PostCourier
	outer	apply tms.SvcFacility#For(p.Source, p.SvcClass, left(p.ZoneCode, 3)) f
	outer	apply tms.BarcodeNbr#Make(p.ZoneCode, r.Number)      b
)