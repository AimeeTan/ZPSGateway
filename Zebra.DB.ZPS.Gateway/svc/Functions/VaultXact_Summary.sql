-- Smile
CREATE FUNCTION [svc].[VaultXact$Summary]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID,      PartyID=p.ID, PartyAlias=p.Alias, BizUnitID, BizUnit=b.Alias
	,		PaymentID, v.CurrencyID,   XactAmt, PrevBal, NextBal, XactedOn,  Supplement
	from	acct.Vault#Raw()           v	
	join	acct.VaultXact#Raw()       x on x.VaultID=v.ID
	join	core.Party#Raw()           p on p.ID=v.PartyID
	cross	apply acct.Contract#For(p.ID, p.Source) c
	join	core.Party#Raw()           b on b.ID=c.BizUnitID
	cross	apply core.Registry#ID()   k
	left	join acct.Payment#Raw()    m on m.ID=x.PaymentID
	left	join core.Supplement#Raw() s on s.RegID =k.Payment and s.RowID=m.ID
)