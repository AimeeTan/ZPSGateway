--bd.he, Smile
CREATE FUNCTION [svc].[Parcel$ClearanceForXpd](@idsInCsv nvarchar(max))
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	p.ID, t.MawbNbr, f.FlightNbr, f.POA, f.POD, f.ETA, f.ETD, p.Weight
    ,		p.RefNbrs, p.RefInfos, r.BrokerID
	from	tvp.I64#Slice(@idsInCsv) x
	join	shpt.SackMft#Base()	     t on x.ID=t.ID
	join	tms.Flight#Raw()	     f on f.ID=t.PID
	join    shpt.Sack#Base()	     s on s.PID=x.ID
	join	shpt.Parcel#Base()	     p on p.PID=s.ID
	join	tms.Route#Raw()          r on r.ID=p.RouteID
	
)--HACK: should move to schema xpd