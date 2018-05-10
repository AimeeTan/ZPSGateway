--Aimee, Ken, bd.he
CREATE FUNCTION [svc].[Parcel$ForStage]()
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	x.ID, x.Source, Stage, RcvHubID, RcvHubAlias, RefNbrs, StatedOn
	,		TenantID=t.ID, TenantAlias=t.Alias,   RouteID, RouteCode
	,		Handler, HandlerID
	from	core.Party#Type() k, shpt.Parcel#Deep() x
	join	core.Party#Raw()  s on s.ID=x.SiteID
	join	core.Party#Raw()  t on t.ID=s.PID
	cross	apply svc.User$ContactName(x.HandlerID) u
)