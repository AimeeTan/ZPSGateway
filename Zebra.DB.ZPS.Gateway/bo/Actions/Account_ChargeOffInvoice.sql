/*

@slip =InvoiceIDsInCsv

*/
--Smile
CREATE PROCEDURE [bo].[Account$ChargeOffInvoice](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@invoiceds I64Array; insert @invoiceds
		select	x.ID from tvp.I64#Slice(@slip) x
		join	acct.Invoice#Raw() v 
		on		v.ID=x.ID
		where	v.DueBalance=v.InvoiceAmt;

		declare	@ledgerSide E8=(select AR from acct.Ledger#Side());
		declare @PayMethod E8=(select Cash from acct.Payment#Method());
		declare @paymentSpec dbo.I64PairAmts;

		with ctePayment as
		(
			select	PartyID, PaidAmt=sum(v.DueBalanceRaw), CurrencyID
			from	@invoiceds           x
			join	acct.Invoice#Raw()   v on x.ID=v.ID
			group	by PartyID, CurrencyID
		)
		insert	acct._Payment
				( PartyID,  LedgerSide,  CurrencyID,  PayMethod,  PaidAmt)
		output    inserted.ID, inserted.PartyID, inserted.PaidAmt into @paymentSpec
		select	PartyID,    @ledgerSide, CurrencyID,  @PayMethod, Amt
		from	ctePayment x
		cross	apply dbo.Currency#Encode(PaidAmt, CurrencyID) c;

		declare	@partyAmts tvp;
		with ctePartyAmts(text) as
		(
			select [text()]=concat( '	,	', RID, '	^	', Amt)
			from	@paymentSpec
			for	xml path(N'')
		)

		select	@partyAmts=Tvp from ctePartyAmts cross	apply tvp.Spr#Purify(text, DEFAULT);
		declare	@vaultType E8=(select Fund from acct.Vault#Type());
		declare	@idAmts  I64PairAmts; insert @idAmts 
		(		LID,     RID,     Amt    )
	--	select	PartyID, VaultID, PrevBal)
		execute	acct.Vault#Upsert @partyAmts=@partyAmts, @vaultType=@vaultType;

		with ctePayment as
		(
			select	PaymentID=x.LID, PartyID=x.RID, PaidAmt=x.Amt, CurrencyID
			from	@paymentSpec x
			cross	apply dbo.Money#Of(x.Amt)
		)
		insert	acct._VaultXact
		(		PaymentID,  InvoiceID, VaultID, PrevBal,  XactAmt)
		select	PaymentID, 0, RID,     x.Amt,     PaidAmt
		from	@idAmts x
		cross	apply dbo.Money#Of(x.Amt) m
		join	ctePayment                p 
		on		p.PartyID=X.LID and p.CurrencyID=m.CurrencyID;
		

		execute acct.Vault#XactByInvoice @invoiceds=@invoiceds, @paymentID=default, @vaultType=@vaultType;

		with	cte as
		(
			select	x.ID, x.DueBalance
			from	acct.Invoice#Raw() x
			join	@invoiceds         i on i.ID=x.ID
		)
		update	cte set DueBalance=0;

		declare	@userID int=(select UserID from loc.Tenancy#Of(@tenancy));
		insert	core._ChangeLog(RegID, RowID, ChangedBy, ChangedOn)
		select			      Invoice,  x.ID,   @userID, getutcdate()
		from	@invoiceds x
		cross	apply core.Registry#ID() r; 


		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
