-- Smile
CREATE	FUNCTION [hub].[Parcel$ForUSDEndOfDay](@hubID int)
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	TotalParcelCnt  =isnull(count(*), 0)
	,		TotalAddOnSvcCnt=isnull(sum(u.TotalUnfinished), 0)
	,		OperationDate   =isnull(cast(dateadd(hour, t.UtcOffset, x.StatedOn) as date), '')
	from	shpt.Parcel#Base()         x
	cross	apply core.AddOnSvc#TotalUnfinished(x.ID) u
	cross	apply core.Source#ID()     s
	join	core.Tenant#Raw()          t on t.ID=x.RcvHubID
	cross	apply core.State#ID()      e
	where	x.Source=s.USD  and x.RcvHubID=@hubID and x.StateID=e.CfmOutGated
	group	by cast(dateadd(hour, t.UtcOffset, x.StatedOn) as date)
)