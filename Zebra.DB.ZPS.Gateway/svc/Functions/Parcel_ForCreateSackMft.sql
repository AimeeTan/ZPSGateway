-- Smile
--TODO: clear old Parcel$ForLoadBalance
CREATE FUNCTION [svc].[Parcel$ForCreateSackMft] ()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID,      Source,   RefNbrs,   RcvHubID, RcvHubAlias, POA,      StateID, StatedOn
	,		RouteID, MftGroup, RouteCode, BrokerID, BrokerAlias, RefInfos, Weight
	from	shpt.Parcel#Deep()    x 
	cross	apply core.Stage#ID() k
	where	x.Stage=k.RouteCfmed
)