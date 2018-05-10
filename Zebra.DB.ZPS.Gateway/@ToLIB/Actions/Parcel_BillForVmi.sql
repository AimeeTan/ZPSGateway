--Smile
CREATE PROCEDURE [shpt].[Parcel#BillForVmi](@parcelIDs dbo.I64Array readonly)
--WITH ENCRYPTION--
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
		with cteInvoice as
		(
			select	LedgerPartyID, x.CurrencyID, c.VaultTag, x.ContractID, ChargeRawAmt=sum(m.RawAmt)
			from	shpt.Parcel#LedgerForVmi(@parcelIDs) x
			join	acct.Charge#Raw() c on c.ID=x.ChargeID
			cross	apply dbo.Money#Of(x.ChargeAmt) m
			where	not exists(
			select	ID from acct.Contract#Raw() t 
			where	t.ID=x.ContractID and t.BillingCycle>0) 
			group	by LedgerPartyID, x.CurrencyID, c.VaultTag, x.ContractID
		)	
		insert	acct._Invoice
		(		PartyID,       VaultTag, LedgerSide, CurrencyID, DueBalance, InvoiceAmt, ContractID)
		output	inserted.ID into @invoiceds
		select	LedgerPartyID, VaultTag, @ledgerSide, x.CurrencyID, x.CurrencyID, m.Amt,    ContractID
		from	cteInvoice x
		cross	apply dbo.Currency#Encode(x.ChargeRawAmt, x.CurrencyID) m
		where	x.ChargeRawAmt>0;

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
		select	LedgerPartyID, MatterID, p.ChargeID, ChargeAmt, p.CurrencyID,  @ledgerSide, iif(ChargeAmt=p.CurrencyID, -1, isnull(i.ID, 0))
		from	shpt.Parcel#LedgerForVmi(@parcelIDs) p
		join	acct.Charge#Raw()  c  on c.ID=p.ChargeID
		left	join cteInvoiced   i  on i.PartyID=p.LedgerPartyID 
										 and i.VaultTag=c.VaultTag
										 and i.CurrencyID=p.CurrencyID
										 and i.ContractID=p.ContractID;
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