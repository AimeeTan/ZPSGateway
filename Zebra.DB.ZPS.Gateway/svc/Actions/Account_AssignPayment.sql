/*
declare	@slip tvp =Tuplet<PartyID, CurrencyID, ChequeAmount, ChequeBalance>
        @context  =Many[Triad<ID, PayAmt, PayBalAmt>]
*/
--Smile
CREATE PROCEDURE [svc].[Account$AssignPayment](@slip tvp, @context tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		--declare	@partyID int, @currencyID tinyint, @amount bigint, @balAmt bigint;
		--select	@partyID=v1,  @currencyID=v2,      @amount=m.Amt,  @balAmt=b.Amt
		--from	tvp.Tuplet#Of(@slip, default)    x
		--cross	apply dbo.Money#Make(x.v3, x.v2) m
		--cross	apply dbo.Money#Make(x.v4, x.v2) b
		--;
		--with cteInvoice as
		--(
		--	select  ID=cast(x.v1 as bigint), DueBalance, NewDueBlance=n.Amt
		--	from	tvp.Triad#Slice(@context, default, default) x
		--	join	acct.Invoice#Raw()                          i on cast(x.v1 as bigint)=i.ID
		--	cross	apply dbo.Money#Make(x.v2, @currencyID)     b
		--	cross	apply dbo.Money#Make(x.v3, @currencyID)     c
		--	cross	apply dbo.Money#Sum( b.Amt, c.Amt)          s
		--	cross	apply dbo.Money#Sum(-s.Amt, i.DueBalance)   n
		--)		
		--update cteInvoice set DueBalance=NewDueBlance 
		--;
		----insert Payment
		--declare	@paymentID I64, @ledgerSide E8=(select AR from acct.Ledger#Side());
		--declare	@payMethod E8=(select Cash from acct.Payment#Method());
		--insert	acct._Payment
		--		( PartyID,  LedgerSide,  CurrencyID,  PayMethod,  PaidAmt)
		--values	(@partyID, @ledgerSide, @currencyID, @payMethod, @amount);
		--select	 @paymentID=scope_identity()
		--;
		
		--declare	@invoiceID I64=0 -- 0: wihtout invoice.
		--declare	@vaultType  E8=(select Fund from acct.Vault#Type());
		--declare @xactAmt bigint=(select Amt from dbo.Money#Sum(-@balAmt, @amount));
		--execute	acct.Vault#Xact    @paymentID=@paymentID, @invoiceID=@invoiceID
		--,		@partyID=@partyID, @vaultType=@vaultType, @xactAmt=@xactAmt
		--;
		--declare	@invoiceds acct.InvoicedSpec;
		--insert	into @invoiceds
		--select	@partyID, x.v1, @vaultType, Amt, @CurrencyID
		--from	tvp.Triad#Slice(@context, default, default)  x
		--cross	apply dbo.Money#Make(x.v2, @currencyID)      b
		--;
		--execute acct.Vault#XactVia @invoiceds=@invoiceds , @paymentID=@paymentID;

		--select	@vaultType=CreditMemo from acct.Vault#Type();
		--execute	acct.Vault#Xact    @paymentID=@paymentID, @invoiceID=@invoiceID
		--,		@partyID=@partyID, @vaultType=@vaultType, @xactAmt=@balAmt
		--;
		--declare	@creditInvoiceds acct.InvoicedSpec;
		--insert	into @creditInvoiceds
		--select	@partyID, x.v1, @vaultType, Amt, @CurrencyID
		--from	tvp.Triad#Slice(@context, default, default)  x
		--cross	apply dbo.Money#Make(x.v3, @currencyID)      b
		--;
		--execute acct.Vault#XactVia @invoiceds=@creditInvoiceds, @paymentID=@paymentID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END