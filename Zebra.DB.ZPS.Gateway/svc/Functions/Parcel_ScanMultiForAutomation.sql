--Eason
CREATE FUNCTION [svc].[Parcel$ScanMultiForAutomation](@numbersInCsv tvp, @minStage E32=PreMin, @maxStage E32=PreMax)
RETURNS TABLE
--WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID, RcvHubID,  Source, SvcType,  CourierID, RouteID
	,       s.Stage, StateID,  POA,    StatedOn, PostedOn
	,		RefNbrs, RefInfos, Number, AddOnServices
	from	core.RefNbr#ScanMulti(@numbersInCsv, @minStage, @maxStage) s
	join	shpt.Parcel#Deep() x on x.ID=s.MatterID 
)
