/*
@slip   =Quad<TenantID, Source, ClientRef, Remark>
@context=Duad[ChargeID, XactAmt]
*/
--Smile
CREATE PROCEDURE [bo].[AssortedFees$Bill](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@tenantID I32,    @source E8,  @supplement nvarchar(max)
		,		@contractID I32,  @billingCycle tinyint, @clientRef loc.RefNbr;
		select	@tenantID=v1,     @source=v2,  @supplement=v4, @clientRef=v3
		,		@contractID=c.ID, @billingCycle=BillingCycle
		from	tvp.Quad#Of(@slip, default)
		cross	apply acct.Contract#For(v1, v2) c;

		declare	@type     E8=(select AssortedFees from core.Matter#Type());
		declare	@matterID I64=next value for core.MatterSeq;
		declare	@userID   I32=(select UserID from loc.Tenancy#Of(@tenancy));
		insert	core._Matter
				(ID,        PosterID, StateID, Stage, Source,  Type, PostedOn)
		values	(@matterID, @tenantID,  0,       0,    @source, @type, getutcdate());

		insert	core._RefNbr(MatterID, Type, Number) select @matterID, ClientRef, @clientRef 
		from	core.RefNbr#Type()

		declare	@regID I32=(select AssortedFees from core.Registry#ID());
		execute	core.Supplement#Merge @regID=@regID, @rowID=@matterID, @supplement=@supplement; 

		declare	@ledgerSide E8=(select AR from acct.Ledger#Side());
		declare	@vaultType  E8=(select Fund from acct.Vault#Type());
		declare	@ledgerIDs I64Array,  @invoiceds I64Array;
		with cteInvoice as
		(
			select	m.CurrencyID, c.VaultTag, XactDecAmt=sum(m.DecAmt)
			from	tvp.Duad#Slice(@context, default, default) x
			join	acct.Charge#Raw()      c on c.ID=cast(x.v1 as int)
			cross	apply dbo.Money#Of(cast(x.v2 as bigint)) m
			where	@billingCycle=0
			group	by m.CurrencyID, c.VaultTag
		)
		insert	acct._Invoice
		(		PartyID,   VaultTag,  LedgerSide, CurrencyID, DueBalance, InvoiceAmt, ContractID)
		output	inserted.ID into @invoiceds
		select	@tenantID, VaultTag, @ledgerSide, CurrencyID, CurrencyID, m.Amt,   @contractID
		from	cteInvoice x
		cross	apply dbo.Money#Make(x.XactDecAmt, x.CurrencyID) m;
	    
		with	cteInvoiced as
		(
			select	x.ID, PartyID, CurrencyID, VaultTag, ContractID
			from	@invoiceds x
			join	acct.Invoice#Raw() i on x.ID=i.ID
		)
		insert	acct._Ledger
		(		PartyID,   MatterID, ChargeID, ChargeAmt,  CurrencyID, LedgerSide,  InvoiceID)
		output	inserted.ID into @ledgerIDs
		select	@tenantID, @matterID, x.v1,    x.v2,     p.CurrencyID, @ledgerSide, isnull(i.ID, 0)
		from	tvp.Duad#Slice(@context, default, default) x
		cross	apply dbo.Money#Of(x.v2)                 p
		join	acct.Charge#Raw()  c on c.ID=cast(x.v1 as int)
		left	join cteInvoiced   i on i.VaultTag=c.VaultTag
									and i.CurrencyID=p.CurrencyID;
										
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

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
