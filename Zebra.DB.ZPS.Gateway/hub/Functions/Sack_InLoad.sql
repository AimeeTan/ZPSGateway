-- Eva
CREATE	FUNCTION [hub].[Sack$InLoad](@sackloadID I64)
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID,  Stage,   StateID, StatedOn,      HubID,    POD, POA
	,		BrokerID, ClrMethodID, Weight=SackWt, PostedOn, FlightID
	,		SackNbr=r.Number
	from	shpt.Sack#Base()         x
	cross	apply core.RefNbr#Type() s
	join	core.RefNbr#Raw()        r on r.MatterID=x.ID and r.Type=s.MIT
	where	x.AID=@sackloadID
)