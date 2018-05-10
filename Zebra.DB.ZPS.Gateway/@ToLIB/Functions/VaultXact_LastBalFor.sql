--Smile.Wang
CREATE FUNCTION [acct].[VaultXact#LastBalFor](@vaultID int)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID, PrevBalRaw=x.RawAmt
	from	acct.VaultXact#Raw()                  v
	cross	apply dbo.Money#Sum(PrevBal, XactAmt) p	
	cross	apply dbo.Money#Of(p.Amt)             x
	where	ID=
	           (select	top(1) ID=last_value(ID) over (order by (select 0))	
				from	acct.VaultXact#Raw()		
				where	VaultID=@vaultID
			   )
	
)
