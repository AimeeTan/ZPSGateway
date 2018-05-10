--PeterHo
CREATE FUNCTION [svc].[Batch$Summary](@siteID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with cteSummary as
	(
		select	x.ID, x.BatchedOn, x.ErrorCnt, t.UtcOffset
		,		FailureCnt=isnull(count(case when p.SvcZone=0 then 1        end), 0)
	--	,		FailureWt =isnull(sum  (case when p.SvcZone=0 then p.Weight end), 0)
		,		SuccessCnt=isnull(count(case when p.SvcZone>0 then 1        end), 0)
	--	,		SuccessWt =isnull(sum  (case when p.SvcZone>0 then p.Weight end), 0)
		from	shpt.Batch#Raw()  x
		join	core.Tenant#Raw() t on t.ID=x.SiteID
		join	shpt.Parcel#Raw() p on p.BatchID=x.ID
		where	x.SiteID=@siteID
		group	by x.ID, x.ErrorCnt, x.BatchedOn, t.UtcOffset
	)
	select	ID, ErrorCnt, FailureCnt, SuccessCnt, BatchedOn=l.LocalTime
	from	cteSummary cross apply dbo.DT#ToLocal(BatchedOn, UtcOffset) l
)
