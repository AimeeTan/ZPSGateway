-- Smile
CREATE FUNCTION [hub].[Sack$DetailForPrint](@sackID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	RouteID=t.ID, FmCountryCode=c.CountryCode, SackSeq=isnull(q.SeqNbr, 0)
	,		x.PostedOn
	from	shpt.Sack#Base()          x
	cross	apply core.Contact#Type() k
	join	core.Contact#Raw() c on x.HubID=c.PartyID and c.Type=k.Billing
	join	tms.Route#Raw()    t on t.ClrMethodID=x.ClrMethodID and t.BrokerID=x.BrokerID
	cross	apply shpt.Sack#SeqNbrOf(x.ID) q
	where	x.ID=@sackID
)