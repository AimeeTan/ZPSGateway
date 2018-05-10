-- Smile
CREATE FUNCTION [svc].[Account$VaultSummary](@partyID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	select	CurrencyID, VaultBal, VaultType, LockCnt
	from	acct.Vault#Raw() x
	cross	apply(
					select	LockCnt=count(*)
					from	core.Matter#Raw()     m
					cross	apply core.State#ID() s
					where	m.StateID=s.CreditLimitExceeded
				 ) l
	cross	apply acct.Vault#Type() t
	where	x.VaultType=t.Fund and x.PartyID=@partyID
)
