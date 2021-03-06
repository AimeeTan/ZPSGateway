﻿--Simile, PeterHo
CREATE FUNCTION [bo].[Account$ExportForFreightInvoice]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	InvoicedOn, InvoiceNbr, i.PartyID, NetDays=isnull(BillingCycle,0)
	,		DueDate, BillTo=c.Tvp, l.FreightTvp
	from	acct.Invoice#Raw()                    i
	join	core.Party#Raw()                      p  on p.ID = i.PartyID
	join	acct.Contract#Raw()                   t  on t.ID=i.ContractID
	cross	apply core.Contact#Type()             k
	outer	apply core.Contact#TvpFor(i.PartyID,  k.Billing) c
	cross	apply acct.Ledger#FreightTvpFor(i.ID) l
	cross	apply acct.Vault#Tag()                d
	cross	apply acct.Ledger#Side()              s
	where	i.DueBalance>0 and i.VaultTag=d.NotDuty and i.LedgerSide=s.AR and BillingCycle>0
)
