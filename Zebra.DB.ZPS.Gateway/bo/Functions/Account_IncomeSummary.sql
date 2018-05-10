--Simile
CREATE FUNCTION [bo].[Account$IncomeSummary]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, TalliedOn, x.CurrencyID,  x.ChargeAmt,ChargeID, BillingCycle
	,		x.PartyID, TenantAlias=p.Alias, BizUnitID,  BizUnit=b.Alias, POA
	,	    a.Source, RefNbrs, RefInfos, PostedOn,  RcvHubAlias, Supplement=''
	from	acct.Ledger#Raw()   x 
	join	core.Tenant#Raw()   p on p.ID=x.PartyID
	join	shpt.Parcel#Deep()  a on a.ID=x.MatterID
	join	acct.Contract#Raw() c on c.ID=a.ContractID
	join	core.Party#Raw()    b on b.ID=c.BizUnitID
	cross	apply core.Source#ID() e
	where	a.Source in (e.eShip, e.eVMI) and x.InvoiceID>-1
	union all
	select	x.ID, TalliedOn, x.CurrencyID,  x.ChargeAmt,ChargeID, BillingCycle
	,		x.PartyID, TenantAlias=p.Alias, BizUnitID,  BizUnit=b.Alias, POA=''
	,	    a.Source, RefNbrs='', RefInfos='', PostedOn,  RcvHubAlias=t.Alias
	,	    Supplement=''
	from	acct.Ledger#Raw() x
	join	core.Tenant#Raw()   p on p.ID=x.PartyID
	join	whse.StockInOrder#Base() a on a.ID=x.MatterID
	join	acct.Contract#Raw() c on c.ID=a.ContractID
	join	core.Party#Raw()    b on b.ID=c.BizUnitID
	join	core.Tenant#Raw()   t on t.ID=a.RcvHubID
	cross	apply core.Source#ID() e
	where	a.Source in (e.eShip, e.eVMI) and x.InvoiceID>-1
	union all
	select	x.ID, TalliedOn, x.CurrencyID,  x.ChargeAmt,ChargeID, BillingCycle
	,		x.PartyID, TenantAlias=p.Alias, BizUnitID,  BizUnit=b.Alias, POA=''
	,	    a.Source, RefNbrs='', RefInfos='', PostedOn,  RcvHubAlias=''
	,	    Supplement
	from	acct.Ledger#Raw()        x
	join	core.Tenant#Raw()        p on p.ID=x.PartyID
	cross	apply core.Matter#Type() m
	join	core.Matter#Raw()        a on a.ID=x.MatterID 
	cross	apply acct.Contract#For(x.PartyID, a.Source) c
	join	core.Party#Raw()         b on b.ID=c.BizUnitID
	cross	apply core.Registry#ID() r 
	join	core.Supplement#Raw()    s on s.RegID =r.Ledger and s.RowID=x.ID
	cross	apply core.Source#ID() e
	where	a.Source in (e.eShip, e.eVMI) and x.InvoiceID>-1
	union all
	select	x.ID, TalliedOn, x.CurrencyID,  x.ChargeAmt,ChargeID, BillingCycle
	,		x.PartyID, TenantAlias=p.Alias, BizUnitID,  BizUnit=b.Alias, POA=''
	,	    a.Source, RefNbrs='', RefInfos='', PostedOn,  RcvHubAlias=''
	,	    Supplement
	from	acct.Ledger#Raw()        x
	join	core.Tenant#Raw()        p on p.ID=x.PartyID
	cross	apply core.Matter#Type() m
	join	core.Matter#Raw()        a on a.ID=x.MatterID 
	cross	apply acct.Contract#For(x.PartyID, a.Source) c
	join	core.Party#Raw()         b on b.ID=c.BizUnitID
	cross	apply core.Registry#ID() r 
	join	core.Supplement#Raw()    s on s.RegID =r.AssortedFees and s.RowID=a.ID
	cross	apply core.Source#ID() e
	where	a.Source in (e.eShip, e.eVMI) and x.InvoiceID>-1



)
