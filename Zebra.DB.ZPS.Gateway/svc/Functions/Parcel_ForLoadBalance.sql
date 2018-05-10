-- Smile, PeterHo, Aimee
CREATE FUNCTION [svc].[Parcel$ForLoadBalance] (@stage int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, RefNbrs, RcvHubID,  RcvHubAlias, POA, StateID, StatedOn, Source
	,		RouteID,     RouteCode, BrokerID,    BrokerAlias
	from	shpt.Parcel#Deep() 	
	where	Stage=@stage
)