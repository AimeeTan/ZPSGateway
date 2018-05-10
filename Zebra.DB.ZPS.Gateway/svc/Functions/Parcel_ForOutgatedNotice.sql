-- For eForward Notice
-- Daxia
CREATE FUNCTION [svc].[Parcel$ForOutgatedNotice]()
RETURNS TABLE
WITH  ENCRYPTION
AS RETURN
(
	select	x.ID, SvcType, Weight,          LastMilerAlias,      SiteAlias
	,		x.RefNbrs,     m.RefStamps,     m.MawbNbr,           FlightNbr
	,		HubCountryCode=c.CountryCode,   SackSeqNbr=isnull(n.SeqNbr, 0)
	,		SackPostedOn=isnull(p.PostedOn, N'0001-01-01'), x.StatedOn
	,		ETA=isnull(ETA, N'0001-01-01'), ETD=isnull(ETD, N'0001-01-01')
	,		HubUtcOffset=isnull(a.UtcOffset, 0), OutgatedOn=isnull(a.UtcTime, '')
	from	core.State#ID() i, shpt.Parcel#Deep()   x
	cross	apply core.Matter#Type() k
	outer	apply (
					select	SackMftID=ID 
					from	core.Matter#PNodeUp(x.ID) d
					where	Type=k.SackMft) s
	left	join  shpt.SackMft#Deep()       m on m.ID=s.SackMftID 
	left	join  shpt.Sack#Base()          p on p.ID=x.PID
	outer	apply core.Activity#TrackSpecific(x.ID, 48700) a--i.OutGated) a
	outer	apply shpt.Sack#SeqNbrOf(p.ID)  n
	outer	apply (
		select	top(1) CountryCode
		from	core.Contact#Type() k, core.Contact#Raw() c 
		where	c.PartyID=p.HubID and c.Type=k.Billing
	) c
)