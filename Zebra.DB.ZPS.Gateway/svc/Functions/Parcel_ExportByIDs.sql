-- fangyi, Smile
CREATE FUNCTION [svc].[Parcel$ExportByIDs](@parcelIDs tvp)
RETURNS TABLE 
--WITH ENCRYPTION
AS RETURN 
(
	select	p.ID, HandlerID, Handler=Alias, Source, RouteCode
	,		POA, RefNbrs, RefInfos, Stage, StateID
	from	tvp.I64#Slice(@parcelIDs) x
	join	shpt.Parcel#Deep()        p on p.ID=x.ID
	join	core.User#Raw()           u on u.ID=p.HandlerID
)
