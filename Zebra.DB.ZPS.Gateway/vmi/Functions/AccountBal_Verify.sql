--Smile
CREATE FUNCTION [vmi].[AccountBal$Verify](@acctID int, @svcType int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	v.ID, v.CurBal
	from	tms.SvcType#For(@svcType, @acctID) x
	join	tms.SvcType#Raw()                  e on e.ID=x.ID
	cross	apply acct.Vault#Type()            k
	join	acct.Vault#Raw()                   v on v.PartyID=@acctID 
												and v.CurrencyID=e.CurrencyID 
												and v.VaultType=k.Fund

)
