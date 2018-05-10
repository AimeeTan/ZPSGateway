/*
@slip    tvp =Triad<PartyID, XactAmt, PayMethod>
@context tvp =Many[Duad<PartyID, AssignedAmt>]
@result  tvp =Duad<PaymentID, XactAmt>
*/
--Smile
CREATE PROCEDURE [co].[PaymentPlan$Init](@slip tvp, @context tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@partyID I32, @paidAmt amt, @paidDecAmt float,    @payMethod E8, 	@currencyID E8;
		select	@partyID=v1,  @paidAmt=v2,  @paidDecAmt=m.DecAmt, @payMethod=v3,  @currencyID=m.CurrencyID
		from	tvp.Triad#Of(@slip, default) x
		cross	apply dbo.Money#Of(v2)       m;

		if(@partyID=0) throw  50000, N'{{ Please Log In! }}', 0; --Hack, Timeout issue

		declare	@planedAmt float;
		select	@planedAmt=round(sum(m.DecAmt/s.ForPayment), 2)
		from	tvp.Duad#Slice(@context, default, default) x
		cross	apply dbo.Money#Of(x.v2)                   m
		join	svc.CurrencyRate$Summary() s on s.FmCurrencyID=@currencyID and s.ToCurrencyID=m.CurrencyID;

		if(@planedAmt>@paidDecAmt) throw  50000, N'{{ Please Confirm The Paid Amt! }}', 0;

		declare	@paymentID I64, @ledgerSide E8=(select AR from acct.Ledger#Side());
	
		insert	acct._Payment
				( PartyID, XID, LedgerSide,  CurrencyID,  PayMethod,  PaidAmt)
		values	(@partyID, 1,  @ledgerSide, @currencyID, @payMethod, @paidAmt);
		select	 @paymentID=scope_identity();
		
		declare	@regID I32=(select PaymentPlan from core.Registry#ID());
		execute	core.Supplement#Merge @regID=@regID, @rowID=@paymentID, @supplement=@context;
		
		select	@result=Tvp from tvp.Duad#Make(@paymentID, @paidAmt);
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END