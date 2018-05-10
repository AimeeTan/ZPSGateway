--Smile
CREATE FUNCTION [vmi].[Parcel$SummaryVia](@idsInCsv nvarchar(max))
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, Stage, x.Source, SvcType, RcvHubID, RcvHubAlias=h.Alias, TenantID=t.ID, TenantAlias=t.Alias
	,		RefNbrs, RefInfos, x.PostedOn
	from	tvp.I64#Slice(@idsInCsv) i
	join	shpt.Parcel#Base() x on x.ID=i.ID
	join	core.Party#Raw()   h on h.ID=x.RcvHubID
	join	core.Party#Raw()   p on p.ID=x.SiteID
	join	core.Party#Raw()   t on t.ID=p.PID
	cross	apply core.Source#ID() k
	where	x.Source=k.eVMI
)