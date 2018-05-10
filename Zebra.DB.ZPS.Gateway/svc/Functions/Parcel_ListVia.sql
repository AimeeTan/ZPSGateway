/*
  ToAaron:
	Should not use Parcel$List() any more, avoid 2100 parameters error for now.
	Don't use me, this will be dropped after brokerage dequeue refactoring.
*/
-- AaronLiu
CREATE FUNCTION [svc].[Parcel$ListVia](@idsInCsv nvarchar(max))
RETURNS TABLE 
WITH SCHEMABINDING
AS RETURN 
(
	select	x.ID,	   Source,	  PostedOn,		 Stage,	   StateID,	   StatedOn, BatchID,  RcvHubID,   SiteID
	,		RouteID,   RouteCode, CourierID,	 BrokerID, SvcType,	   SvcZone,  SvcClass, CmdyRootID, Weight
	,		Length,	   Width,     Height,		 POA,      RefNbrs,	   RefInfos, Ledgers,  Challenges, LastMilerCode
	,		HandlerID, Handler,   AddOnServices, HasIDNbr, HasConcern, ZoneCode
	from	tvp.I64#Slice(@idsInCsv) i,	svc.Parcel$List() x
	where	i.ID=x.ID
)