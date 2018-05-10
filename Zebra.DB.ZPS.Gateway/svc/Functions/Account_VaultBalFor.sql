-- Smile
CREATE FUNCTION [svc].[Account$VaultBalFor](@partyID int)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID=PartyID, VaultBal, InvoicedAmt, UninvoicedAmt, CurrencyID, VaultType, CurBal, CreditLimit
	from	acct.Vault#Raw()  x
	where	x.PartyID=@partyID 
)
