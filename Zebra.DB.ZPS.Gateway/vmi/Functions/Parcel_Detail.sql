--Smile
CREATE FUNCTION [vmi].[Parcel$Detail]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, Source, PostedOn,  Stage,  StateID, StatedOn,  OutgatedOn=isnull(OutgatedOn,'')
	,		RcvHubID, RcvHubAlias, SiteID, SiteAlias, RefNbrs, RefInfos
	,		SvcType,  t.CourierCode, t.CourierNbr, t.Tracks
	from	shpt.Parcel#Deep()           x
	cross	apply svc.Parcel$Track(x.ID) t
	outer	apply(
					select	top(1) OutgatedOn=TalliedOn
					from	core.Activity#Raw()   a
					join    core.State#Raw()      t on a.StateID=t.ID
					cross	apply core.Stage#ID() k
					where	Stage=k.Outgated and MatterID=x.ID
					
				) c
	cross	apply core.Source#ID() k
	where	x.Source=k.eVMI
)