-- Ken
CREATE FUNCTION [svc].[Account$StorageFees]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID, m.Source, TenantID=p.ID, PartyAlias=Alias
	,		Supplement, TalliedOn, ChargeAmt, CurrencyID, ChargeID 
	from	acct.Ledger#Raw()          x
	cross	apply core.Matter#Type()   k
	join	core.Matter#Raw()          m on m.ID=x.MatterID and m.Type=k.StorageFee
	join	core.Tenant#Raw()          p on p.ID=x.PartyID
	cross	apply core.Registry#ID()   r 
	join	core.Supplement#Raw() s on s.RegID=r.Ledger and s.RowID=x.ID

)