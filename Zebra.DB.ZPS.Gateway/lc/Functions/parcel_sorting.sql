/*
	Activities = Tuplet<ID, Operator, ActionID, Stage, TailledOn>
*/
--AaronLiu
CREATE FUNCTION [lc].[Parcel$Sorting](@number varchar(40))
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	with cteParcel as
	(
		select	p.ID, p.RcvHubID, p.Stage, p.RouteID, p.RouteCode, p.SvcType, p.POA
		from	core.RefNbr#ScanOne(@number, default, default) x
		join	shpt.Parcel#Deep() p on x.MatterID=p.ID
	),	cteActivities(text) as
	(
		select	[text()]=concat
		(		k.Many,	  a.ID,			k.Tuplet,	 u.Alias
		,		k.Tuplet, a.ActionID,	k.Tuplet,	 s.Stage
		,		k.Tuplet, dateadd(hour, t.UtcOffset, TalliedOn)
		)
		from	tvp.Spr#Const() k, cteParcel	x
		cross	apply core.Matter#PNodeUp(x.ID) m
		join	core.Activity#Raw() a on a.MatterID=m.ID
		join	core.Tenant#Raw()	t on t.ID=x.RcvHubID
		join	core.State#Raw()    s on s.ID=a.StateID
		join	core.Party#Raw()    u on u.ID=a.UserID
		for		xml path('')
	)
	select	x.ID, x.Stage, x.RouteID, x.RouteCode, x.SvcType, x.POA, Activities=Tvp
	from	cteParcel x, cteActivities
	cross	apply tvp.Spr#Purify(text, default) 
)