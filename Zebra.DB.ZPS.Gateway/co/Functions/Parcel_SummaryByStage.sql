-- Smile
CREATE FUNCTION [co].[Parcel$SummaryByStage](@tenantID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	select	isnull(sum(case when x.Stage between 100   and  9999 then 1 else 0 end),0) as ParcelAwaiting
	,		isnull(sum(case when x.Stage between 10000 and 19999 then 1 else 0 end),0) as ParcelProcessing
	,		isnull(sum(case when x.Stage between 20000 and 24999 then 1 else 0 end),0) as ParcelShipped	
	from	core.Matter#Raw()        x
	cross	apply core.Matter#Type() t
	where	x.Type=t.Parcel 
	and		x.PosterID in 
	(
		select	ID 
		from	core.Party#Raw()        p
		cross	apply core.Party#Type() k
		where	p.PID=@tenantID and     p.Type=k.TenantSite
	)	
)
