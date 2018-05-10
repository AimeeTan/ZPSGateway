-- AaronLiu
CREATE FUNCTION [svc].[Appointment$ListForRamper](@ramperID I64)
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	x.ID,	    x.SiteID,   SiteType=c.Type, x.PostedOn, x.Stage, x.StateID
	,		x.StatedOn, x.PickupOn, x.RefNbrs,		 x.RefInfos
	from	shpt.Appointment#Base() x
	cross	apply core.Party#Role() r
	cross	apply core.RefParty#Of(x.ID, r.Ramper) p
	join	core.Party#Raw()  c on x.SiteID=c.ID
	where	p.PartyID=@ramperID
)