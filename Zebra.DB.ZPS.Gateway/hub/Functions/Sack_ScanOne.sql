-- AaronLiu, Eva
CREATE FUNCTION [hub].[Sack$ScanOne](@number varchar(40))
RETURNS	TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	ID,  s.Stage, StateID, StatedOn,      HubID,    POD, POA
	,		BrokerID, ClrMethodID, Weight=SackWt, PostedOn, FlightID
	,		SackNbr=r.Number
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	shpt.Sack#Base()         s on s.ID=x.MatterID
	cross	apply core.RefNbr#Type() t
	join	core.RefNbr#Raw()        r on r.MatterID=s.ID and r.Type=t.MIT
)
