-- PeterHo ,Irene
CREATE FUNCTION svc.Parcel$CriteriaForLoadBalance()
RETURNS TABLE 
WITH SCHEMABINDING, ENCRYPTION
AS RETURN 
(
	with cteSummary as
	(
		select	x.RcvHubID, x.POA, r.BrokerID, r.MftGroup, x.RouteID
		,		TotalParcelCnt=isnull(count(*), 0)
		,		TotalParcelWt =isnull(sum(cast(x.Weight as float)), 0)
		from	shpt.Parcel#Base()       x
		join	tms.Route#Raw()          r on r.ID=x.RouteID
		cross	apply core.Stage#ID()    k
		cross	apply core.Matter#Type() m
		where	x.Stage=k.RouteCfmed and x.PID=0 and x.Type=m.Parcel
		group	by x.RcvHubID, x.POA, r.BrokerID, r.MftGroup, x.RouteID
	)
	select	RcvHubID, RcvHubAlias=t.Alias
	,		BrokerID, b.BrokerAlias,  POA
	,		MftGroup, TotalParcelCnt, RouteID
	,		TotalParcelWt
	from	cteSummary           x
	join	core.Tenant#Raw()    t on t.ID=x.RcvHubID
	join	brkg.Broker#Raw()    b on b.ID=x.BrokerID
)
