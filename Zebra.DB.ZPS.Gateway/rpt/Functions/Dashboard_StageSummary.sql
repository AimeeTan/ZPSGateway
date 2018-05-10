-- Eason
CREATE FUNCTION [rpt].[Dashboard$StageSummary](@siteID bigint)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	select	isnull(sum(case when x.Stage between 100   and 24999 then 1 else 0 end),0) as ParcelTotal
	,		isnull(sum(case when x.Stage between 100   and  9999 then 1 else 0 end),0) as ParcelAwaiting
	,		isnull(sum(case when x.Stage between 10000 and 19999 then 1 else 0 end),0) as ParcelProcessing
	,		isnull(sum(case when x.Stage between 20000 and 24999 then 1 else 0 end),0) as ParcelShipped
	,		isnull(sum(case when x.Stage in (500,10500,20500)    then 1 else 0 end),0) as ExcptionTotal
	,		isnull(sum(case when x.Stage = 500                   then 1 else 0 end),0) as ExcptionAwaiting
	,		isnull(sum(case when x.Stage = 10500                 then 1 else 0 end),0) as ExcptionProcessing
	,		isnull(sum(case when x.Stage = 20500                 then 1 else 0 end),0) as ExcptionShipped
	from	core.Matter#Raw()        x
	cross	apply core.Matter#Type() t
	where	x.Type=t.Parcel and x.PosterID=@siteID
)
