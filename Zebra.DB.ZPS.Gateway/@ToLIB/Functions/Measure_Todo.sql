-- AaronLiu
CREATE FUNCTION [core].[Measure#Todo](@matterID I64, @tenancy tvp)
RETURNS TABLE
-- WITH ENCRYPTION
AS RETURN
(
	with cte as
	(
		select	m.ID, m.Type,  Adopt, QueueRakedIn, HubMeasure, ReportOverThreshold
		,		HubMeasureMPS, HubMeasureCPS, HubMeasureOrphan
		from	core.Matter#Raw() m, core.Action#ID() a
		where	m.ID=@matterID
	), cteTodo as
	(
		select	ActionID=x.HubMeasureMPS, ExeActionID=x.QueueRakedIn, TobeTenancy=@tenancy
		from	cte x, core.Matter#Type() t
		where	x.Type=t.HouseParcel
		union	all
		select	ActionID=x.HubMeasureCPS, ExeActionID=x.QueueRakedIn, TobeTenancy=@tenancy
		from	cte x, core.Matter#Type() t
		where	x.Type=t.MediumParcel
		union	all
		select	ActionID=x.HubMeasureOrphan, ExeActionID=x.QueueRakedIn, TobeTenancy=@tenancy
		from	cte x, core.Matter#Type() t
		where	x.Type=t.OrphanParcel
		union	all
		select	ActionID=0, ExeActionID=x.ReportOverThreshold, TobeTenancy=t.Tenancy
		from	cte x
		cross	apply loc.Tenancy#As(@tenancy, 0) t
		join	shpt.Parcel#Raw() p on p.ID=x.ID
		join	tms.Route#Raw()	  r on r.ID=p.RouteID
		where	r.MaxWeight>0 and p.Weight>r.MaxWeight
		union	all
		select	ActionID=0, ExeActionID=x.HubMeasure, TobeTenancy=@tenancy
		from	cte x
	)
	select	top(1) ActionID, ExeActionID, TobeTenancy
	from	cteTodo
)