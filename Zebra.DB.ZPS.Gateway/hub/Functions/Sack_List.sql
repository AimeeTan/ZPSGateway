-- Eva
CREATE	FUNCTION [hub].[Sack$List]()
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	x.ID, SackNbr=r.Number, Stage, StateID,  StatedOn, HubID, POD, POA
	,		RouteID=t.ID, PostedOn, ParcelCnt
	from	shpt.Sack#Base()             x
	cross	apply core.RefNbr#Type()     s
	join	core.RefNbr#Raw()            r on r.MatterID=x.ID and r.Type=s.MIT
	join	tms.Route#Raw()              t on t.ClrMethodID=x.ClrMethodID and t.BrokerID=x.BrokerID
	cross	apply hub.Sack#Parcels(x.ID) n
)