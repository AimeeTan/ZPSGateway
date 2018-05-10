--Daxia
CREATE	FUNCTION [ic].[SackMft$ForOutgated]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, MawbNbr, FlightNbr, Stage,       StatedOn
	,		POA,  POD,     p.RouteID, t.RouteCode
	,		[TotalParcelCnt]=isnull(p.TotalParcelCnt, 0)
	from	shpt.SackMft#Deep()	  x
	cross	apply
	(
		select	TotalParcelCnt=count(*), RouteID
		from	core.Matter#Raw() m cross apply core.Matter#Type() k
		join	shpt.Parcel#Base()  t on t.PID=m.ID 
		where	m.PID=x.ID group by t.RouteID
	) p
	join	tms.Route#Raw() t on t.ID=p.RouteID
)