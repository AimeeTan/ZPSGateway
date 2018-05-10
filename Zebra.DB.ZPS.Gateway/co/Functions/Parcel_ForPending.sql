--Ken
CREATE FUNCTION [co].[Parcel$PendingFor](@days tinyint,@tenantID int)
RETURNS TABLE
WITH SCHEMABINDING,ENCRYPTION
AS RETURN
(
	select	ParcelCnt=count(ID), Date=x.Value 
	from	dbo.Calendar#Raw()            x
	cross	apply core.Stage#Boundary()   s
	left	join shpt.Parcel#Base()       p 
	on		x.Value=cast(StatedOn as date)  and p.Stage between s.PreMin and s.PreMax
	and		p.SiteID in 
	(
		select	ID 
		from	core.Party#Raw()         t
		cross	apply core.Party#Type()  k
		where	t.PID=@tenantID and      t.Type=k.TenantSite
	)	
	where  Value between dateadd(day, -@days+1, cast(getutcdate() as date)) and cast(getutcdate() as date) 
	group  by x.Value 
)