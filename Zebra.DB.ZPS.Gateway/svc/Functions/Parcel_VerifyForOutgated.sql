--Simile
CREATE FUNCTION [svc].[Parcel$VerifyForOutgated](@numbersInCsv tvp)
RETURNS TABLE
--WITH  ENCRYPTION
AS RETURN
(
	select	ID=isnull(p.ID, 0), TrackingNbr=x.Number
	,		POA=isnull(p.POA, '')
	,		RcvHubID=isnull(p.RcvHubID, 0)
	,		RcvHubAlias=isnull(t.Alias, '')
	from	loc.RefNbr#Slice(@numbersInCsv)                       x
	outer	apply core.RefNbr#ScanOne(x.Number, default, default) r
	left	join shpt.Parcel#Raw() p on p.ID=r.MatterID
	left	join core.Tenant#Raw() t on t.ID=p.RcvHubID
)
