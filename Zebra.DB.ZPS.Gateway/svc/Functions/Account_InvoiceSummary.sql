-- Smile
CREATE FUNCTION [svc].[Account$InvoiceSummary]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID, PartyID, PartyAlias=p.Alias, InvoiceNbr, CurrencyID, VaultTag
	,		InvoiceAmt=isnull(InvoiceAmt,0), DueBalance=isnull(DueBalance,0)
	,		InvoicedOn=isnull(InvoicedOn, '0001-01-01'), BizUnitID
	,		BizUnit=b.Alias
	from	acct.Invoice#Raw()  x
	join	core.Party#Raw()    p on x.PartyID=p.ID
	join	acct.Contract#Raw() c on c.ID=x.ContractID
	join	core.Party#Raw()    b on b.ID=c.BizUnitID
	where	x.ID>0	and x.DueBalance>0 and c.BillingCycle>0
)