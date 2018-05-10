/*
declare	@slip tvp = Tuplet[Source, VaultTag, PartyID, BizUnitID, IssueDate0, InvoiceNbrInfo]
*/
--@slip=Quad[];
--Smile
CREATE PROCEDURE [svc].[Account$InvoiceTallied](@slip tvp)
WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@source tinyint, @vaultTag tinyint, @partyID int, @bizUnitID int, @issueDate datetime2(2)
		,		@invoiceNbrInfo tvp;
		select	@source=v1, @vaultTag=v2, @partyID=v3, @bizUnitID=v4, @issueDate=v5
		,		@invoiceNbrInfo=v6	
		from	tvp.Tuplet#Of(@slip, default) 

		declare	@ledgerSide E8=(select AR from acct.Ledger#Side())
		,		@ids I64Array;	
		with cte as
		(
			select	ID=cast(v1 as bigint), InvoiceNbr=v2
			from	tvp.Duad#Slice(@invoiceNbrInfo, default, default)
		)
		insert	acct._Invoice( PartyID,      ContractID,   VaultTag,   LedgerSide,  InvoiceNbr,
							   CurrencyID,   DueBalance,   InvoiceAmt, IssueDate, DueDate)
		output	inserted.ID into @ids
		select	               PartyID,      ContractID,   VaultTag,   @ledgerSide, e.InvoiceNbr,
		                       CurrencyID,   ChargeAmt,    ChargeAmt,  IssueDate, DueDate
		from	svc.Invoice$ProcessingList(@source, @vaultTag, @partyID, @bizUnitID, @issueDate) x
		join	cte e on e.ID=x.ID;

		with	cteLedgerGroup as
		(
		select	l.ID, l.PartyID, x.SourceID, p.ContractID, l.CurrencyID, g.VaultTag
		,		IssueDate=iif(BillingCycle%7=0, cd.BOWeek, cd.BOMonth)
		,		l.ChargeRaw, LastInvoiceDate=isnull(i.LastInvoiceDate, dbo.DT@Empty()),	l.TalliedOn, BillingCycle
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
						and     ID not in (select ID from @ids)
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
		select	ID, PartyID, SourceID, ContractID, CurrencyID, VaultTag
		,		IssueDate, ChargeRaw
		,		InvoiceGroup=DateDiff(day, TalliedOn, dateadd(day, -1,IssueDate))/BillingCycle
		from	cteLedgerGroup               x
		where	(BillingCycle in(7,14) and datediff(day, LastInvoiceDate, IssueDate)>=BillingCycle)
		or		(BillingCycle=30 and datediff(month, LastInvoiceDate, IssueDate)=1)
		), cteInvoice as
		(
		select	ID, PartyID, VaultTag, CurrencyID, ContractID, InvoiceGroup, IssueDate
		,		ChargeRawAmt=sum(ChargeRaw) over(partition	by PartyID, VaultTag, CurrencyID, ContractID, InvoiceGroup, IssueDate)
		from	cteInvoiceSummary  		
		), cteLedger as
		(
		select	InvoiceID=x.ID, LedgerID=d.ID
		from	@ids               x
		join	acct.Invoice#Raw() i on x.ID=i.ID
		join	cteInvoice         d on d.PartyID=i.PartyID       and 
										d.ContractID=i.ContractID and 
										d.CurrencyID=i.CurrencyID and 
										d.VaultTag=i.VaultTag     and
										d.ChargeRawAmt=i.DueBalanceRaw
		)update l set l.InvoiceID=i.InvoiceID from acct._Ledger l join cteLedger i on l.ID=I.LedgerID;

		declare	@vaultType  E8=(select Fund from acct.Vault#Type());
		with cteInvoiceds as
		(
			select	PartyID, x.CurrencyID, ChargeRawAmt=sum(x.InvoiceRawAmt)
			from	@ids               i
			join	acct.Invoice#Raw() x on i.ID=x.ID
			group	by PartyID, x.CurrencyID
		), cteVaults as
		(
			select	v.ID,  UninvoicedAmt, NewUninvoicedAmt=iif(u.Amt<0, 0, u.Amt)
			from	acct.Vault#Raw() v
			join	cteInvoiceds     x on v.PartyID=x.PartyID and v.CurrencyID=x.CurrencyID and v.VaultType=@vaultType
			cross	apply dbo.Currency#Encode(x.ChargeRawAmt, x.CurrencyID) m
			cross	apply dbo.Money#Sum(-m.Amt,v.UninvoicedAmt) u
		)
		update	cteVaults set UninvoicedAmt=NewUninvoicedAmt;
		

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END