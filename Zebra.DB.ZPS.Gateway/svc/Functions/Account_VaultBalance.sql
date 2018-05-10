-- Smile
CREATE FUNCTION [svc].[Account$VaultBalance]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID=PartyID, TenantAlias=a.Alias, VaultBal, InvoicedAmt, UninvoicedAmt, CurrencyID, VaultType, CurBal, CreditLimit
	,		BizUnitID=ISNULL(BizUnitID, 0), BizUnit=ISNULL(p.Alias, N''), BillingCycle
	from	acct.Vault#Raw()         x
	join	core.Party#Raw()         a on a.ID=x.PartyID
	cross	apply acct.Contract#For(x.PartyID, a.Source) c
	join	core.Party#Raw()         p on p.ID=c.BizUnitID
)
