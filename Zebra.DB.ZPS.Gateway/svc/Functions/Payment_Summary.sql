-- Smile
CREATE FUNCTION [svc].[Payment$Summary]()
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	x.ID, TenantID=x.PartyID, TenantAlias=t.Alias, CurrencyID, PayMethod, PaidAmt, PaidOn
	,		BizUnitID, BizUnit=p.Alias, Supplement	
	from	acct.Payment#Raw() x
	join	core.Party#Raw()   t on t.ID=x.PartyID
	cross	apply acct.Contract#For(x.PartyID, t.Source) c
	join	core.Party#Raw()   p on p.ID=c.BizUnitID
	cross	apply core.Registry#ID()   k
	left	join core.Supplement#Raw() s on s.RegID=k.Payment and s.RowID=x.ID
	where	x.ID>1 and XID<1
)