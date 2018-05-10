--Eva
CREATE	FUNCTION [svc].[SackMft$ExportForOutgate]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID,    x.FlightNbr, x.MawbNbr, MftPostedOn=x.PostedOn, x.BrokerID, x.POD, x.POA, x.HubAlias
	,		SackNbrs=s.RefNbrs
	,		p.RefNbrs, p.RefInfos, p.Weight, p.RouteID, p.PostedOn
	from	shpt.SackMft#Deep() x
	join	shpt.Sack#Base()    s on s.PID=x.ID
	join	shpt.Parcel#Deep()  p on p.PID=s.ID

	UNION

	select	x.ID,    x.FlightNbr, x.MawbNbr, MftPostedOn=x.PostedOn, x.BrokerID, x.POD, x.POA, x.HubAlias
	,		SackNbrs=N''
	,		p.RefNbrs, p.RefInfos, p.Weight, p.RouteID, p.PostedOn
	from	shpt.SackMft#Deep() x
	join	shpt.Parcel#Deep()  p on p.PID = x.ID
)



