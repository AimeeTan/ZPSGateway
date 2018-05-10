-- Smile, PeterHo, FJJ, PeterHo, Smile
CREATE FUNCTION [svc].[Account$Ledger]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID,      d.Source,    ChargeAmt, CurrencyID
	,		TalliedOn, x.PartyID,   PartyAlias=p.Alias
	,		Weight,    SvcType,     RefInfos,  RefNbrs
	,		SectionWt, g.VaultTag,  NetDays=isnull(BillingCycle, 0)
	,		BizUnitID, BizUnit=n.Alias, ChargeID, x.MatterID
	from	acct.Ledger#Raw()        x
	join	core.Party#Raw()         p on p.ID=x.PartyID
	join	shpt.Parcel#Base()       d on d.ID=x.MatterID
	join	acct.Charge#Raw()        g on g.ID=x.ChargeID
	join	acct.Contract#Raw()      t on t.ID=d.ContractID
	join	core.Party#Raw()         n on n.ID=t.BizUnitID
	cross	apply acct.Ledger#Side() s 
	cross	apply tms.SvcRate#For(d.SvcType, d.RcvHubID, d.Weight) a
	where	x.LedgerSide=s.AR
)