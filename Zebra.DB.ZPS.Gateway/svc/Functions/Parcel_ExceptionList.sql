-- Smile, Ken, bd.he, Daxia
CREATE FUNCTION [svc].[Parcel$ExceptionList]()
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	x.ID,    x.StateID, StatedOn, Stage,    Source, SvcType, POA, HandlerID, u.Handler
	,		RouteID, RouteCode, RefNbrs,  RefInfos, RoledActions,    LastMessage=m.Body
	from	shpt.Parcel#Deep() x cross apply core.Registry#ID() k
	cross	apply svc.User$ContactName(x.HandlerID)             u
	outer	apply core.Message#BodyOfLast(k.Matter, x.ID)       m
)
