--ken, Smile
CREATE FUNCTION [ic].[Parcel$WithConcern](@concernType tinyint)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, Stage, SvcType,   Source, RouteID, RouteCode, StatedOn, RefNbrs, RefInfos
	,		Handler,  HandlerID,    Concerns
	from	shpt.Parcel#Deep()                      x 
	cross	apply core.Concern#Tvp(x.ID)            t
	cross	apply svc.User$ContactName(x.HandlerID) u
	where   exists (
						select	MatterID
						from	core.Concern#Raw() where x.ID=MatterID 
						and		(Type=@concernType or nullif(@concernType, 0) is null)
					)
	
)
