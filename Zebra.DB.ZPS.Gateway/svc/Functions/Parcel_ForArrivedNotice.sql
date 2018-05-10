-- For eForward Notice
-- Daxia
CREATE FUNCTION [svc].[Parcel$ForArrivedNotice](@parcelIDS nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	p.ID,      SiteAlias
	,		p.RefNbrs, RefStamps=isnull(f.RefStamps, N'')
	from	shpt.Parcel#Base()      p 
	join	shpt.Sack#Base()        s on s.ID=p.PID	
	join	shpt.SackMft#Base()     m on m.ID=s.PID
	join	tms.Flight#Base()       f on f.ID=m.PID
	where	p.ID in (select ID from tvp.I64#Slice(@parcelIDS))
)