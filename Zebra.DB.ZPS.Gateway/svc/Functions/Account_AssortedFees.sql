-- Ken
CREATE FUNCTION [svc].[Account$AssortedFees]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID, TenantID=p.ID, Alias, m.Source, Supplement
	,		ChargeAmt, TalliedOn, ChargeID, CurrencyID, ClientRefNbr=b.Number 
	from	acct.Ledger#Raw()          x
	cross	apply core.Matter#Type()   k
	join	core.Matter#Raw()          m on m.ID=x.MatterID and m.Type=k.AssortedFees
	join	core.Tenant#Raw()          p on p.ID=x.PartyID
	cross	apply core.RefNbr#Type()   t
	join	core.RefNbr#Raw()          b on b.MatterID=m.ID and b.Type=t.ClientRef
	cross	apply core.Registry#ID()   r 
	join	core.Supplement#Raw()      s on s.RegID=r.AssortedFees and s.RowID=m.ID

)