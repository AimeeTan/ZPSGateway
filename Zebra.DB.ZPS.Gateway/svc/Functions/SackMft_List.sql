--Aimee, Smile, AaronLiu, hbd
CREATE	FUNCTION [svc].[SackMft$List]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID,	      MawbNbr, FlightID=x.PID, FlightNbr,    PostedOn,  Stage, StateID
	,		StatedOn,   HubID, HubAlias,       HubUtcOffset, RefStamps, RoledActions
	,		UnSackedParcelCnt, UnTransloadedSackCnt, Source
	,		POA, [POAUtcOffset]=a.UtcOffset, [POAUtcPlaceID]=a.UtcPlaceID
	,		POD, [PODUtcOffset]=d.UtcOffset, [PODUtcPlaceID]=d.UtcPlaceID
	from	shpt.SackMft#Deep()	  x
	join	core.Port#Raw() a on  x.POA=a.Code
	join	core.Port#Raw() d on  x.POD=d.Code
	cross	apply (
		select	UnSackedParcelCnt   =isnull(sum(case when m.Type=t.Parcel and m.Level=1             then 1 else 0 end),0)
		,		UnTransloadedSackCnt=isnull(sum(case when m.Type=t.Sack   and m.Stage<s.Transloaded then 1 else 0 end),0)
		from	core.Matter#PNodeDn(x.ID) m
		cross	apply core.Matter#Type()  t
		cross	apply core.Stage#ID()     s
	) n
)