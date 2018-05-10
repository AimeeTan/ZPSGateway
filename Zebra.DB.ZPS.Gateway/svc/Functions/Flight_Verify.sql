/*
	@flights = Many[Traid<POD, POA, Airline>]
*/
-- AaronLiu
CREATE FUNCTION [svc].[Flight$Verify](@flights tvp)
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	Seq=isnull(x.Seq,0), Airline=x.v3,    AirlineID=isnull(l.ID,0), POD=x.v1, POA=x.v2
	,		[PODUtcOffset]=isnull(d.UtcOffset,0), [PODUtcPlaceID]=isnull(d.UtcPlaceID,0)
	,		[POAUtcOffset]=isnull(a.UtcOffset,0), [POAUtcPlaceID]=isnull(a.UtcPlaceID,0)
	from	tvp.Triad#Slice(@flights, default, default) x
	left	join core.Port#Raw()   d on x.v1=d.Code
	left	join core.Port#Raw()   a on x.v2=a.Code
	left	join tms.Airline#Raw() l on x.v3=l.Alias
)