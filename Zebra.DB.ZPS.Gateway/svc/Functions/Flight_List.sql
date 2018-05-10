-- AaronLiu
CREATE FUNCTION [svc].[Flight$List]()
RETURNS	TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID,  FlightNbr, PostedOn, Stage, StateID, StatedOn, RefStamps, RoledActions
	,		POD, [PODUtcOffset]=d.UtcOffset, [PODUtcPlaceID]=d.UtcPlaceID, ETD
	,		POA, [POAUtcOffset]=a.UtcOffset, [POAUtcPlaceID]=a.UtcPlaceID, ETA
	from	tms.Flight#Base()	 x
	join	core.Port#Raw() a on x.POA=a.Code
	join	core.Port#Raw() d on x.POD=d.Code
)
