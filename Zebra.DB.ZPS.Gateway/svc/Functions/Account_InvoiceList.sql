--Ken, PeterHo, Smile
CREATE FUNCTION [svc].[Account$InvoiceList]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID,	    CurrencyID, DueBalance,  InvoiceAmt
	,		InvoicedOn, InvoiceNbr, x.VaultTag, x.PartyID, Alias
	,		DueDate, RemainingDays=datediff(day, getutcdate(), DueDate)
	from	acct.Invoice#Raw()       x
	join	core.Party#Raw()         p  on p.ID = x.PartyID
	join	acct.Contract#Raw()      c on c.ID=x.ContractID
	where	x.DueBalance>0  and c.BillingCycle>0
)