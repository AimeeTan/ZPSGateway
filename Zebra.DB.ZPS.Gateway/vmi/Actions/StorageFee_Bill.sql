/*
@slip    =Triad[TenantAlias, ChargeID, Volume]
@context =Duad<Source, HubAlias>
@result  =Comma[MatterID]
*/
--Smile
CREATE PROCEDURE [vmi].[StorageFee$Bill](@slip tvp,  @context tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN	TRY
		BEGIN	TRAN;
		
		declare	@source E8=(select eVMI from core.Source#ID());
		declare	@hubID I32=(select t.ID from tvp.Duad#Of(@context, default) x 
							join   core.Tenant#Raw() t on t.Alias=x.v2);

		declare	@ledgers dbo.I64TrioAmts; --PartyID, MatterID, ChargeID, Amt
		with cte as
		(
			select	TenantID=t.ID, ChargeID=cast(x.v2 as int), Cbm=x.v3, CurrencyID
			,		Rate= (
							  case cast(x.v2 as int) 
							  when k.StorageCbmFee30Day then r.StorageCbmFee30Day
							  when k.StorageCbmFee60Day then r.StorageCbmFee60Day
							  else StorageCbmFeeOther end
						  )

			from	tvp.Triad#Slice(@slip, default, default) x
			cross	apply loc.TenantAlias#Encode(x.v1)       d
			join	core.Tenant#Raw()                        t on t.Source=@source and t.Alias=d.TenantAlias
			cross	apply whse.StorageRate#For(@hubID, t.ID) r
			cross	apply acct.Charge#ID()                   k			
		)
		insert	@ledgers select TenantID, next value for core.MatterSeq, ChargeID, Amt
		from	cte x
		cross	apply dbo.Money#Make(Cbm*Rate, CurrencyID) m
		where	not exists(
								select	ID
								from	acct.Ledger#Raw() 
								where	PartyID=x.TenantID
								and		ChargeID=x.ChargeID
								and		cast(TalliedOn as date)=cast(getutcdate() as date)
								)
		;

		declare	@type  E8=(select StorageFee from core.Matter#Type());
		insert	core._Matter
		(		ID,  PosterID,  StateID,  Stage,  Source,  Type, PostedOn   )
		select	MID,  @hubID,         0,      0, @source, @type, getutcdate()
		from	@ledgers;

		declare	@ledgerSide E8=(select AR from acct.Ledger#Side());
		declare	@invoiceds  I64Array; 
		declare	@vaultType  E8=(select Fund from acct.Vault#Type());
		declare	@vaultTag   E8=(select NotDuty from acct.Vault#Tag());

		with cteInvoice as
		(
			select	LedgerPartyID=x.LID, CurrencyID, ContractID=c.ID, ChargeRawAmt=sum(m.RawAmt)
			from	@ledgers x			
			cross	apply acct.Contract#For(x.LID, @source) c
			cross	apply dbo.Money#Of(x.Amt)               m
			where	not exists(
								select	ID from acct.Contract#Raw() t 
								where	t.ID=c.ID and t.BillingCycle>0
			) 
			group	by x.LID, m.CurrencyID, c.ID
		)	
		insert	acct._Invoice
		(		PartyID,       VaultTag, LedgerSide, CurrencyID, DueBalance, InvoiceAmt, ContractID)
		output	inserted.ID into @invoiceds
		select	LedgerPartyID, @vaultTag, @ledgerSide, x.CurrencyID, x.CurrencyID, m.Amt,    ContractID
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
		select	x.LID, x.MID, x.RID, x.Amt, m.CurrencyID,  @ledgerSide, iif(x.Amt=m.CurrencyID, -1, isnull(i.ID, 0))
		from	@ledgers x
		cross	apply dbo.Money#Of(x.Amt) m
		cross	apply acct.Contract#For(x.LID, @source) c
		left	join cteInvoiced       i  on i.PartyID=x.LID
										 and i.CurrencyID=m.CurrencyID
										 and i.ContractID=c.ID
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

		declare	@supplements tvp;
		with cte as
		(
			select	l.ID, Cbm=x.v3
			,		Rate= (
							  case cast(x.v2 as int) 
							  when k.StorageCbmFee30Day then r.StorageCbmFee30Day
							  when k.StorageCbmFee60Day then r.StorageCbmFee60Day
							  else StorageCbmFeeOther end
						  )

			from	tvp.Triad#Slice(@slip, default, default) x
			cross	apply loc.TenantAlias#Encode(x.v1)       d
			join	core.Tenant#Raw()                        t on t.Source=@source and t.Alias=d.TenantAlias
			cross	apply whse.StorageRate#For(@hubID, t.ID) r
			cross	apply acct.Charge#ID()                   k	
			join	acct.Ledger#Raw()                        l			
			on		l.PartyID=t.ID
			and		l.ChargeID= cast(x.v2 as int) 
			where	l.ID in (select ID from @ledgerIDs)
		)
		insert	core._Supplement(RegID, RowID, Supplement)
		select	k.Ledger, x.ID, concat(x.Cbm, N'CBM', ' * ', x.Rate)
		from	core.Registry#ID() k, cte x

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END