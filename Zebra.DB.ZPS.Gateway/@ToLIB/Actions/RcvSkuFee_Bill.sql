--Smile
CREATE PROCEDURE [whse].[RcvSkuFee#Bill](@orderIDs dbo.I64Array readonly)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

	-- 1	Insert  Invoice(s):
		declare	@ledgerSide E8=(select AR from acct.Ledger#Side());
		declare	@invoiceds I64Array; 
		declare	@vaultType  E8=(select Fund from acct.Vault#Type());

		declare	@chargeID  I32,  @vaultTag E8;
		select	@chargeID=ID,    @vaultTag=VaultTag
		from	acct.Charge#ID() k, acct.Charge#Raw() c
		where	c.ID=k.RcvSkuFee;

		with cteInvoice as
		(
			select	LedgerPartyID=p.AID, CurrencyID, x.ContractID, ChargeRawAmt=sum(m.RawAmt)
			from	whse.StockInOrder#Base()                         x
			join	core.Party#Raw()                                 p on p.ID=x.SiteID
			cross	apply whse.StorageRate#For(x.RcvHubID, x.SiteID) s
			cross	apply dbo.Money#Make(s.RcvSkuFee*x.TotalSkuQty, s.CurrencyID) m
			where	not exists(
								select	ID from acct.Contract#Raw() t 
								where	t.ID=x.ContractID and t.BillingCycle>0
			) 
			and		x.ID in (select ID from @orderIDs)
			group	by P.AID, s.CurrencyID, x.ContractID
		)	
		insert	acct._Invoice
		(		PartyID,       VaultTag, LedgerSide, CurrencyID, DueBalance, InvoiceAmt, ContractID)
		output	inserted.ID into @invoiceds
		select	LedgerPartyID, @vaultTag, @ledgerSide, x.CurrencyID, 0,         m.Amt,    ContractID
		from	cteInvoice x
		cross	apply dbo.Currency#Encode(x.ChargeRawAmt, x.CurrencyID) m;

		declare	@ledgerIDs I64Array;
		with	cteInvoiced as
		(
			select	x.ID, PartyID, CurrencyID, VaultTag, ContractID
			from	@invoiceds x
			join	acct.Invoice#Raw() i on x.ID=i.ID
		)
		-- 2	Insert  Ledger(s):
		insert	acct._Ledger
		(		PartyID,       MatterID,   ChargeID, ChargeAmt,   CurrencyID,   LedgerSide, InvoiceID)
		output	inserted.ID into @ledgerIDs
		select	p.AID, x.ID, @chargeID, m.Amt, s.CurrencyID,  @ledgerSide, isnull(i.ID,0)
		from	whse.StockInOrder#Base()                         x
		join	core.Party#Raw()                                 p on p.ID=x.SiteID
		cross	apply whse.StorageRate#For(x.RcvHubID, x.SiteID) s
		cross	apply dbo.Money#Make(s.RcvSkuFee*x.TotalSkuQty, s.CurrencyID) m
		left	join cteInvoiced       i  on i.PartyID=p.AID 
										 and i.CurrencyID=s.CurrencyID
										 and i.ContractID=x.ContractID
		where	x.ID in (select ID from @orderIDs)
		;		
		with cteUnInvoiceds as
		(
			select	PartyID, x.CurrencyID, ChargeRawAmt=sum(x.ChargeRaw)
			from	@ledgerIDs l
			join	acct.Ledger#Raw() x on x.ID=l.ID
			where	InvoiceID=0
			group	by PartyID, x.CurrencyID
		), cteVaults as
		(
			select	PartyID, CurrencyID, ChargeAmt=m.Amt
			from	cteUnInvoiceds x
			cross	apply dbo.Currency#Encode(x.ChargeRawAmt, x.CurrencyID) m
		)
		merge	acct._Vault as o using cteVaults as n
		on		(o.PartyID=n.PartyID and o.VaultType=@vaultType and o.CurrencyID=n.CurrencyID)
		when	matched then
				update set UninvoicedAmt=(select Amt from dbo.Money#Sum(n.ChargeAmt, o.UninvoicedAmt)), TalliedOn=getutcdate()
		when	not matched then
				insert(  PartyID,   VaultBal,    VaultType,   CurrencyID,   UninvoicedAmt)
				values(n.PartyID, n.CurrencyID, @vaultType, n.CurrencyID, n.ChargeAmt)
		;
		execute acct.Vault#XactByInvoice @invoiceds=@invoiceds, @paymentID=default, @vaultType=@vaultType;


		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
