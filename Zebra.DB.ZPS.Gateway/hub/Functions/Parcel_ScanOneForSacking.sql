-- AaronLiu
CREATE	FUNCTION [hub].[Parcel$ScanOneForSacking](@number varchar(40))
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	x.ID, x.Stage, x.StateID, x.PID, x.POA, RouteID, x.BrokerID, r.ClrMethodID, x.Weight, x.RefNbrs
	from	shpt.Parcel#Deep()  x
	join	tms.Route#Raw()	    r on x.RouteID=r.ID
	join	core.RefNbr#ScanOne(@number, default, default) m on m.MatterID=x.ID
)