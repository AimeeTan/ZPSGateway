-- Eason
CREATE FUNCTION [rpt].[Dashboard$Summary](@siteID bigint, @timezoneOffset int=0)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	select	LastDayParcel   =isnull(SUM(case when cl.DOffset - c.DOffset <=1               then 1 else 0 end), 0)
	,		Last7DParcel    =isnull(SUM(case when cl.DOffset - c.DOffset <=7               then 1 else 0 end), 0)
	,		Pre7DParcel     =isnull(SUM(case when cl.DOffset - c.DOffset between 7 and 14  then 1 else 0 end), 0)
	,		Last30DParcel   =isnull(SUM(case when cl.DOffset - c.DOffset <=30              then 1 else 0 end), 0)
	,		Pre30DParcel    =isnull(SUM(case when cl.DOffset - c.DOffset between 30 and 60 then 1 else 0 end), 0)
	,		LastMonthParcel =isnull(SUM(case when cl.MOffset - c.MOffset =0                then 1 else 0 end), 0)
	,		PreMonthParcel  =isnull(SUM(case when cl.MOffset - c.MOffset =1                then 1 else 0 end), 0)

	,       LastDaySales    =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset <=1               , r.Sales, 0)),2), 0)
	,		Last7DSales     =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset <=7               , r.Sales, 0)),2), 0)
	,		Pre7DSales      =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset between 7 and 14  , r.Sales, 0)),2), 0)
	,		Last30DSales    =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset <=30              , r.Sales, 0)),2), 0)
	,		Pre30DSales     =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset between 30 and 60 , r.Sales, 0)),2), 0)
	,		LastMonthSales  =isnull(ROUND(SUM(iif(cl.MOffset - c.MOffset =0                , r.Sales, 0)),2), 0)
	,		PreMonthSales   =isnull(ROUND(SUM(iif(cl.MOffset - c.MOffset =1                , r.Sales, 0)),2), 0)

	,       LastDayFreight  =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset <=1               , f.Freight, 0)), 2), 0)
	,		Last7DFreight   =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset <=7               , f.Freight, 0)), 2), 0)
	,		Pre7DFreight    =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset between 7 and 14  , f.Freight, 0)), 2), 0)
	,		Last30DFreight  =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset <=30              , f.Freight, 0)), 2), 0)
	,		Pre30DFreight   =isnull(ROUND(SUM(iif(cl.DOffset - c.DOffset between 30 and 60 , f.Freight, 0)), 2), 0)
	,		LastMonthFreight=isnull(ROUND(SUM(iif(cl.MOffset - c.MOffset =0                , f.Freight, 0)), 2), 0)
	,		PreMonthFreight =isnull(ROUND(SUM(iif(cl.MOffset - c.MOffset =1                , f.Freight, 0)), 2), 0)

	from	core.Matter#Raw()         x
	cross	apply core.Matter#Type()  mt
	cross	apply core.RefInfo#Type() rt
	cross	apply tvp.Spr#Const()     sp
	cross   apply dbo.Calendar#Of(DATEADD(HOUR,  -@timezoneOffset, GETUTCDATE())) cl
	join	dbo.Calendar#Raw() c on cast(x.PostedOn as Date)=c.Value
	cross	apply
	(
			select	Sales=isnull(sum(m.DecAmt), 0)
			from	core.RefInfo#Of(x.ID,rt.DeclaredInfo)           x
			cross	apply tvp.Quad#Slice(x.Info, default, sp.Mucho) t 
			cross	apply dbo.Money#Of(t.v3) m
	) r
	cross	apply
	(
			select	Freight=isnull(sum(m.DecAmt), 0)
			from	acct.Ledger#Raw()               g
			cross	apply acct.Charge#ID()          c
			cross	apply dbo.Money#Of(g.ChargeAmt) m
			where	g.MatterID=x.ID and g.ChargeID=c.Freight
	) f
	where	c.DOffset between (cl.DOffset - 60) and cl.DOffset 
	and		x.Type=mt.Parcel
	and		x.PosterID=@siteID
)