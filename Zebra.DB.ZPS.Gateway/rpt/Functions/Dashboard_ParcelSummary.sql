-- Eason
CREATE FUNCTION [rpt].[Dashboard$ParcelSummary](@siteID bigint, @startDate datetime, @endDate datetime, @timezoneOffset int=0)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	c.Value as [Date]
	,		Parcel=isnull(count(*), 0)
	,		Sales =round(sum(isnull(s.Sales, 0)), 2)
	from	core.Matter#Raw()         x
	cross	apply core.Matter#Type()  mt
	cross	apply core.RefInfo#Type() rt
	cross	apply tvp.Spr#Const()     sp
	cross   apply dbo.Calendar#Of(DATEADD(HOUR, -@timezoneOffset, @startDate)) sd
	cross   apply dbo.Calendar#Of(DATEADD(HOUR, -@timezoneOffset, @endDate  )) ed
	join	dbo.Calendar#Raw() c on cast(x.PostedOn as Date)=c.Value
	cross	apply
	(
		select	Sales=isnull(sum(m.DecAmt), 0)
		from	core.RefInfo#Of(x.ID,rt.DeclaredInfo)           i
		cross	apply tvp.Quad#Slice(i.Info, default, sp.Mucho) t
		cross	apply dbo.Money#Of(t.v3)                        m
	) s
	where	c.DOffset between sd.DOffset and ed.DOffset
	and		x.Type=mt.Parcel
	and		x.PosterID=@siteID
	group	by c.Value
);
