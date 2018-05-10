--AaronLiu
CREATE FUNCTION [hub].[Activity$Lookup](@number varchar(40))
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	a.ID, Operator=u.Alias, a.ActionID, s.Stage
	,		OperatedOn=isnull(dateadd(hour, t.UtcOffset, TalliedOn), N'0001-01-01')
	from	core.RefNbr#ScanOne(@number, default, default) x
	cross	apply core.Matter#PNodeUp(x.MatterID) m
	join	core.Activity#Raw() a on a.MatterID=m.ID
	join	shpt.Parcel#Raw()	p on p.ID=x.MatterID
	join	core.Tenant#Raw()	t on t.ID=p.RcvHubID
	join	core.State#Raw()    s on s.ID=a.StateID
	join	core.Party#Raw()    u on u.ID=a.UserID
)