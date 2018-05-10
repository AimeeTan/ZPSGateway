-- For eForward Notice
-- Daxia
-- TODO: Must add new Onboarded LocalTime
CREATE FUNCTION [svc].[Parcel$ForOnboardedNotice](@idInCsv nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	p.ID,      SiteAlias
	,		p.RefNbrs, m.RefStamps
	from	tvp.I64#Slice(@idInCsv)   x
	join	shpt.SackMft#Base()       m on m.ID=x.ID
	left	join shpt.Sack#Base()     s on s.PID=x.ID
	join	shpt.Parcel#Base()        p on p.PID=s.ID or p.PID=x.ID
)