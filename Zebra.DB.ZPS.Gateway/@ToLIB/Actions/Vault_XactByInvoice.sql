--Smile
CREATE PROCEDURE [acct].[Vault#XactByInvoice](@invoiceds I64Array readonly, @paymentID bigint =0, @vaultType tinyint)
WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
						
		-- 1	Upsert  Vault(s):
		with cteVaultGroup as
		(
			select	PartyID, i.CurrencyID, XactAmt=sum(-m.RawAmt)
			from	@invoiceds         x
			join	acct.Invoice#Raw() i on i.ID=x.ID
			cross	apply dbo.Money#Of(i.InvoiceAmt) m 
			group	by PartyID, i.CurrencyID
		), cteVault as
		(
			select	PartyID, CurrencyID, XactAmt=m.Amt
			from	cteVaultGroup                                    x
			cross	apply dbo.Currency#Encode(x.XactAmt, CurrencyID) m
		)
		merge	acct._Vault as o using cteVault as n
		on		(o.PartyID=n.PartyID and o.VaultType=@vaultType and o.CurrencyID=n.CurrencyID)
		when	matched  then update set VaultBal=(select Amt from dbo.Money#Sum(VaultBal, XactAmt))
										, TalliedOn=getutcdate()
										, InvoicedAmt=(select iif(Amt<o.CurrencyID, o.CurrencyID, Amt) 
										  from dbo.Money#Sum(o.InvoicedAmt, n.XactAmt))
		when	not matched then
				insert(  PartyID,   VaultBal,  VaultType,   CurrencyID)
				values(n.PartyID, n.XactAmt,  @vaultType, n.CurrencyID)
		;

		with cteInvoice as
		(
			select	x.PartyID, InvoiceID=x.ID, VaultID=v.ID, XactAmt=x.InvoiceAmt, XactAmtRaw=c.RawAmt, x.CurrencyID
			,		VaultBalRaw=isnull(PrevBalRaw, 0), Marker=lag(c.RawAmt) over(partition by v.ID order by x.ID)
			from	acct.Invoice#Raw()                    x
			join	 @invoiceds                           d on x.ID=d.ID
			cross	apply dbo.Money#Of(x.InvoiceAmt)      c
			join	acct.Vault#Raw() v on v.PartyID=x.PartyID and v.CurrencyID=x.CurrencyID and v.VaultType=@vaultType
			outer	apply acct.VaultXact#LastBalFor(v.ID) i
		),	cteCummulation as
		(
			select	PartyID, InvoiceID, VaultID, XactAmt, XactAmtRaw, CurrencyID
			,		Cummulation=sum(Marker) over (partition by VaultID  order by InvoiceID)
			,		VaultBalRaw, marker
			from	cteInvoice
		)
		, cteXact as
		(
			select	PartyID, InvoiceID, VaultID, XactAmt, CurrencyID, Cummulation, VaultBalRaw
			,		PrevBalRaw=iif(marker is null, VaultBalRaw, VaultBalRaw-Cummulation)
			from	cteCummulation
		)

		insert	acct._VaultXact
		(		PaymentID, InvoiceID, VaultID, PrevBal,  XactAmt)
		select	@paymentID,InvoiceID, VaultID, m.Amt,   -XactAmt
		from	cteXact                                           x
		cross	apply dbo.Currency#Encode(PrevBalRaw, CurrencyID) m;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END