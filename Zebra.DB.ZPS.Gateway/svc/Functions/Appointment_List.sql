--AaronLiu
CREATE FUNCTION [svc].[Appointment$List]()
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	x.ID,		x.SiteID,	TenantID=t.ID, TenantAlias=t.Alias,		x.PostedOn, x.Stage, x.StateID
	,		x.StatedOn, x.PickupOn, x.EstWeight,   Weight=isnull(Weight,0), x.RefNbrs,  x.RefInfos
	from	shpt.Appointment#Base() x
	join	core.Party#Raw()  s on s.ID=x.SiteID
	join	core.Party#Raw()  t on t.ID=s.PID
	cross	apply (
		select	Weight=isnull(sum(p.Weight),0)
		from	core.Matter#Type() t, core.Matter#ANodeDn(x.ID) m
		join	shpt.Parcel#Raw()  p on m.ID=p.ID
		where	m.Type=t.Parcel
	) c
)