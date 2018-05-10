/*
@slip    tvp =Quad<PartyID, XactAmt, PayMethod, Supplemnt>
*/
--Smile
CREATE PROCEDURE [svc].[Account$Transact](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@partyID I32, @xactAmt amt, @payMethod E8, @supplement nax;
		select	@partyID=v1,  @xactAmt=v2,  @payMethod=v3, @supplement=v4
		from	tvp.Quad#Of(@slip, default)

		
		declare	@paymentID I64, @ledgerSide E8=(select AR from acct.Ledger#Side());
		execute	acct.Payment#Insert    @id=@paymentID out
		,		@partyID=@partyID,     @ledgerSide=@ledgerSide, @xactAmt=@xactAmt
		,		@payMethod=@payMethod, @supplement=@supplement;

		declare	@invoiceID I64=0 -- 0: wihtout invoice.
		declare	@vaultType  E8=(select Fund from acct.Vault#Type());
		execute	acct.Vault#Xact    @paymentID=@paymentID, @invoiceID=@invoiceID
		,		@partyID=@partyID, @vaultType=@vaultType, @xactAmt=@xactAmt;

		if(@xactAmt>0)
			execute	shpt.Parcel#ReleaseByDeposit @partyID=@partyID, @tenancy=null

		declare	@userID I32=(select UserID from	loc.Tenancy#Of(@tenancy)),
				@regID I32=(select Contract from core.Registry#ID());

		insert	core._ChangeLog(RegID,       RowID, ChangedBy, ChangedOn)
		select			      SvcRate,  @paymentID,   @userID, getutcdate()
		from	core.Registry#ID();

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END