--Smile
CREATE FUNCTION [svc].[Invoice$ProcessingList](@source tinyint, @vaultTag tinyint, @partyID int, @bizUnitID int, @issueDate datetime2(2))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with	cteLedgerGroup as
	(
		select	l.PartyID, x.SourceID, p.ContractID, l.CurrencyID, g.VaultTag
		,		IssueDate=iif(BillingCycle%7=0, cd.BOWeek, cd.BOMonth)
		,		l.ChargeRaw, LastInvoiceDate=isnull(i.LastInvoiceDate, dbo.DT@Empty())
		,		l.TalliedOn, BillingCycle
		from	acct.Contract#Raw()               x
		cross	apply dbo.Calendar#Of(@issueDate) cd
		join	shpt.Parcel#Raw()                 p on p.ContractID=x.ID
		join	acct.Ledger#Raw()                 l on l.MatterID=p.ID
		join	acct.Charge#Raw()                 g on l.ChargeID=g.ID
		cross	apply acct.Vault#Tag()            a
		cross	apply acct.Ledger#Side()          d
		outer	apply (
						select  LastInvoiceDate=max(IssueDate)
						from	acct.Invoice#Raw()
						where	PartyID=x.TenantID
						and		ContractID=x.ID
						and		VaultTag=g.VaultTag
						and		CurrencyID=l.CurrencyID
					  )                           i           
		where	l.InvoiceID=0
		and		(nullif(@vaultTag,0) is null or g.VaultTag=@vaultTag)
		and		l.LedgerSide=d.AR
		and		(nullif(@bizUnitID,0) is null or x.BizUnitID=@bizUnitID)
		and		(nullif(@partyID, 0) is null or x.TenantID=@partyID)
		and		(nullif(@source,  0) is null or x.SourceID=@source)
		and		BillingCycle>0
		and	    l.TalliedOn<iif(BillingCycle%7=0, cd.BOWeek, cd.BOMonth)
	), cteInvoiceSummary as
	(
		select	PartyID, SourceID, ContractID, CurrencyID, VaultTag
		,		IssueDate, ChargeRaw
		,		InvoiceGroup=DateDiff(day, TalliedOn, dateadd(day, -1,IssueDate))/BillingCycle
		from	cteLedgerGroup               x
		where	(BillingCycle in(7,14) and datediff(day, LastInvoiceDate, IssueDate)>=BillingCycle)
		or		(BillingCycle=30 and datediff(month, LastInvoiceDate, IssueDate)=1)
	), cteInvoice as
	(
		select	PartyID, VaultTag, CurrencyID, ContractID, InvoiceGroup, IssueDate
		,		ChargeRawAmt=sum(ChargeRaw), LedgerCount=count(*)
		from	cteInvoiceSummary  
		group	by PartyID, VaultTag, CurrencyID, ContractID, InvoiceGroup, IssueDate
	)
	select	ID=isnull(row_number() over(order by (select null)), 0), PartyAlias=p.Alias, CurrencyID, VaultTag, ChargeAmt=c.Amt
	,		t.SourceID, IssueDate, ContractID, InvoiceGroup, PartyID, LedgerCount=isnull(LedgerCount, 0)
	,		DueDate=dateadd(day, iif(VaultTag=k.Duty, DutyTerms, NonDutyTerms), IssueDate)
	from	cteInvoice             x
	join	core.Party#Raw()       p on p.ID=x.PartyID
	cross	apply dbo.Currency#Encode(ChargeRawAmt, CurrencyID)  c
	join	acct.Contract#Raw()    t on t.ID=x.ContractID
	cross	apply acct.Vault#Tag() k
)