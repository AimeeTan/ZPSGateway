--AaronLiu
CREATE FUNCTION [shpt].[Appointment#Base]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID, PID, AID, Source,  Type,	   LockCnt,	 Stage, StateID, StatedOn,	SiteID=m.PosterID
	,		SiteAlias=m.PosterAlias, PostedAt, PostedOn, SiteUtcOffset=m.UtcOffset, PickupOn
	,		EstWeight,  HandlerID,	 RefNbrs,  RefInfos, RefStamps, RefParties,		RoledActions
	,		Challenges, AddOnServices
	from	shpt.Appointment#Raw() x
	join	core.Matter#Deep()	   m on m.ID=x.ID
)