/*
@slip    tvp =Triad<PaymentID, PaidAmt, Suplement>
*/
--Smile
CREATE PROCEDURE [co].[Account$Deposit](@slip tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@paymentID I64, @paidAmt dbo.amt, @supplement nax;
		select	@paymentID=cast(v1 as bigint), @paidAmt=v2, @supplement=s.Tvp
		from	tvp.Triad#Of(@slip, default) x
		cross	apply tvp.Pair#Make(v2, v3)  s;
		
		declare	@isValid bit=0, @paymentPlan tvp, @partyID int;
		select	@isValid=iif(s.Amt<=@paidAmt, 1, 0)
		,		@paymentPlan=t.Supplement
		,		@partyID=x.PartyID
		from	acct.Payment#Raw() x
		cross	apply dbo.Money#Of(x.PaidAmt) m
		cross	apply dbo.Money#Of(@paidAmt)  p
		join	svc.CurrencyRate$Summary()    c on c.FmCurrencyID=m.CurrencyID and c.ToCurrencyID=p.CurrencyID
		cross	apply dbo.Money#Make(m.DecAmt*c.ForPayment, c.ToCurrencyID) s
		cross	apply core.Registry#ID()      g
		join	core.Supplement#Raw()         t on t.RegID=g.PaymentPlan and t.RowID=x.ID
		where	x.XID=1 and x.ID=@paymentID
		
		if(@isValid=1)
		begin
		update	acct._Payment set XID=0 where ID=@paymentID;
		
		declare	@regID I32=(select Payment from core.Registry#ID());
		execute	core.Supplement#Merge @regID=@regID, @rowID=@paymentID, @supplement=@supplement;

		declare	@vaultType E8=(select Fund from acct.Vault#Type());
		declare	@idAmts  I64PairAmts; insert @idAmts 
		(		LID,     RID,     Amt    )
	--	select	PartyID, VaultID, PrevBal)
		execute	acct.Vault#Upsert @partyAmts=@paymentPlan, @vaultType=@vaultType;

		with	cteXact as
		(
			select	PartyID=cast(v1 as bigint)
			,		XactAmt=cast(v2 as bigint), c.CurrencyID
			from	tvp.Duad#Slice(@paymentPlan, default, default)
			cross	apply dbo.Currency#Decode(cast(v2 as bigint)) c
		)
		insert	acct._VaultXact
		(		 PaymentID,  InvoiceID, VaultID, PrevBal,  XactAmt)
		select	@paymentID,          0,     RID,     Amt,  XactAmt
		from	@idAmts x
		cross	apply dbo.Currency#Decode(x.Amt) a
		join	cteXact                          t on a.CurrencyID=t.CurrencyID;

		execute	shpt.Parcel#ReleaseByDeposit @partyID=@partyID, @tenancy=null
		end
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END