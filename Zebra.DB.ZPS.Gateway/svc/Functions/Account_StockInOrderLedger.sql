-- Smile
CREATE FUNCTION [svc].[Account$StockInOrderLedger]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID,      d.Source,    ChargeAmt, CurrencyID
	,		TalliedOn, x.PartyID,   PartyAlias=p.Alias	
	,		NetDays=isnull(BillingCycle, 0), ChargeID
	,		BizUnitID, BizUnit=n.Alias, AsnNbr=a.Number
	from	acct.Ledger#Raw()        x
	join	core.Party#Raw()         p on p.ID=x.PartyID
	join	whse.StockInOrder#Base() d on d.ID=x.MatterID
	join	acct.Contract#Raw()      t on t.ID=d.ContractID
	join	core.Party#Raw()         n on n.ID=t.BizUnitID
	cross	apply core.RefNbr#Type() r
	join	core.RefNbr#Raw()        a on a.MatterID=d.ID and a.Type=r.AsnNbr
	cross	apply acct.Ledger#Side() s 
	where	x.LedgerSide=s.AR
)