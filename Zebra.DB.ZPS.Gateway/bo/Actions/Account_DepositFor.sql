/*
@slip    tvp =Quad<TenantID, PaidAmt, PayMethod, Supplemnt>
@context tvp= Duad<TenantID, XactAmt)
*/
--Smile
CREATE PROCEDURE [bo].[Account$DepositFor](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@partyID I32,   @paidAmt amt,   @paidDecAmt float
		,		@payMethod E8, 	@currencyID E8, @supplement nax;
		select	@partyID=v1,    @paidAmt=v2,  @paidDecAmt=m.DecAmt
		,		@payMethod=v3,  @currencyID=m.CurrencyID, @supplement=v4
		from	tvp.Quad#Of(@slip, default)  x
		cross	apply dbo.Money#Of(v2)       m;

		declare	@planedAmt float;
		select	@planedAmt=round(sum(m.DecAmt/s.ForPayment), 2)
		from	tvp.Duad#Slice(@context, default, default) x
		cross	apply dbo.Money#Of(x.v2)                   m
		join	svc.CurrencyRate$Summary() s on s.FmCurrencyID=@currencyID and s.ToCurrencyID=m.CurrencyID;

		if(@planedAmt>@paidDecAmt) throw  50000, N'{{ Please Confirm The Paid Amt! }}', 0;

		declare	@paymentID I64, @ledgerSide E8=(select AR from acct.Ledger#Side());
		execute	acct.Payment#Insert    @id=@paymentID out
		,		@partyID=@partyID,     @ledgerSide=@ledgerSide, @xactAmt=@paidAmt
		,		@payMethod=@payMethod, @supplement=@supplement;

		declare	@vaultType E8=(select Fund from acct.Vault#Type());
		declare	@idAmts  I64PairAmts; insert @idAmts 
		(		LID,     RID,     Amt    )
	--	select	PartyID, VaultID, PrevBal)
		execute	acct.Vault#Upsert @partyAmts=@context, @vaultType=@vaultType;

		with	cteXact as
		(
			select	PartyID=cast(v1 as bigint)
			,		XactAmt=cast(v2 as bigint), c.CurrencyID
			from	tvp.Duad#Slice(@context, default, default)
			cross	apply dbo.Currency#Decode(cast(v2 as bigint)) c
		)
		insert	acct._VaultXact
		(		 PaymentID,  InvoiceID, VaultID, PrevBal,  XactAmt)
		select	@paymentID,          0,     RID,     Amt,  XactAmt
		from	@idAmts x
		cross	apply dbo.Currency#Decode(x.Amt) a
		join	cteXact                          t on a.CurrencyID=t.CurrencyID;

		execute	shpt.Parcel#ReleaseByDeposit @partyID=@partyID, @tenancy=null
	
		declare	@userID I32=(select UserID from	loc.Tenancy#Of(@tenancy));

		insert	core._ChangeLog(RegID,       RowID, ChangedBy, ChangedOn)
		select			      Payment,  @paymentID,   @userID, getutcdate()
		from	core.Registry#ID();
		
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END