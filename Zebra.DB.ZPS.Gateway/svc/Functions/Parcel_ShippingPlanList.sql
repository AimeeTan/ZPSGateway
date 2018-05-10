-- Aimee, Smile
Create FUNCTION [svc].[Parcel$ShippingPlanList]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, Stage, x.Source, POA, Weight, RefNbrs, RouteID, RouteCode
	,		RcvHubID,  RcvHubAlias, RefInfos, HandlerID, Handler=u.Alias
	from	shpt.Parcel#Deep() x
	join	core.User#Raw()    u on x.HandlerID=u.ID
)
