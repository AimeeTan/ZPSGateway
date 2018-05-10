-- Eva
CREATE FUNCTION [hub].[Sack$ScanOneForMft](@number varchar(40))
RETURNS	TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	s.ID, SackNbr=n.Number, s.Stage, StateID,  StatedOn, HubID, POD, POA
	,		RouteID=r.ID, PostedOn, ParcelCnt
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	shpt.Sack#Base()             s on s.ID=x.MatterID
	join	tms.Route#Raw()              r on r.ClrMethodID=s.ClrMethodID and r.BrokerID=s.BrokerID
	cross	apply core.RefNbr#Type()     t
	join	core.RefNbr#Raw()            n on n.MatterID=s.ID and n.Type=t.MIT
	cross	apply hub.Sack#Parcels(s.ID) p
)
