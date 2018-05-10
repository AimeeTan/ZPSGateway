-- Smile
CREATE FUNCTION [vmi].[Parcel$SummaryByStage](@siteID bigint)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	select	isnull(sum(case when x.Stage >=10000 and x.Stage<12600 then 1  end),0) as AwaitingAudit
	,		isnull(sum(case when x.Stage >=12600 and x.Stage<20000 then 1  end),0) as AwaitingOutgate
	,		isnull(sum(case when x.Stage >=20000 and x.Stage<25000 then 1  end),0) as AwaitingDoorDelivery
	from	core.Matter#Raw()        x
	cross	apply core.Matter#Type() t
	cross	apply core.Source#ID()   k
	where	x.Type=t.Parcel and x.PosterID=@siteID and x.Source=k.eVMI
)