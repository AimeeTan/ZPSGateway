--wangtianqi, Smile
CREATE FUNCTION [svc].[Parcel$WithChallenge]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID,    x.StateID, StatedOn, Stage, Source, SvcType, POA 
	,		HandlerID, RouteID, RouteCode, RefNbrs,  RoledActions, ChallengeBody=c.Body, u.Handler
	from	shpt.Parcel#Deep()            x 
	cross	apply core.Challenge#Of(x.ID) c
	cross	apply svc.User$ContactName(x.HandlerID) u
)
