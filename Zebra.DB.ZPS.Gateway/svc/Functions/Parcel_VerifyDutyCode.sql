--Smile
CREATE	FUNCTION [svc].[Parcel$VefityDutyCode](@dutyCodes nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	p.ID, DutyCode=x.v2, DutyID=isnull(d.ID, 0), DutyRate=isnull(d.DutyRate, 0)
	from	tvp.Duad#Slice(@dutyCodes, default, default) x
	join	shpt.Parcel#Raw()                            p on p.ID=cast(x.v1 as bigint)
	join	tms.Route#Raw()                              t on t.ID=p.RouteID
	join	brkg.ClrMethod#Raw()                         c on c.ID=t.ClrMethodID
	left	join brkg.Duty#Raw()                         d on d.CountryCode=c.CountryCode and d.DutyCode=x.v2
)
