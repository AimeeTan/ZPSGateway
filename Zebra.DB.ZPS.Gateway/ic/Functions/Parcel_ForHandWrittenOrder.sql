--Aimee, bd.he, Daxia
CREATE FUNCTION [ic].[Parcel$ForHandWrittenOrder]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID,    x.Source, Stage, StateID, StatedOn, PostedOn,  PostedAt
	,		RefNbrs, RefInfos, ShopID=SiteID,  ShopAlias=SiteAlias, HandlerID, u.Handler
	from	core.Source#ID()   k, shpt.Parcel#Base() x
	cross	apply svc.User$ContactName(x.HandlerID)  u
	where	x.Source=k.AAE and SvcType=0
)
