
--Smile
CREATE FUNCTION [vmi].[Invoice$SummaryForSasa]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with cte as
	(
			select	x.ID, x.PartyID, VaultBal=c.NextBal, x.CurrencyID, x.TalliedOn, ChargeID, ChargeAmt
			,		ClientRefNbr=N'', RefNbr=r.Number, Supplement=N'', c.XactedOn
			,		SectionWt=0, Weight=0
			from	acct.Ledger#Raw()        x
			join	acct.Vault#Raw()         v on x.PartyID=v.PartyID and x.CurrencyID=v.CurrencyID
			join	acct.VaultXact#Raw()     c on c.VaultID=v.ID and c.InvoiceID=x.InvoiceID
			cross	apply core.RefNbr#Type() k
			join	core.RefNbr#Raw()        r on r.MatterID=x.MatterID and r.Type=k.AsnNbr
			where	x.PartyID in (10983, 10987)
			union all
			select	x.ID, x.PartyID, VaultBal=c.NextBal, x.CurrencyID, x.TalliedOn, ChargeID, ChargeAmt
			,		ClientRefNbr=N'', RefNbr=N'', Supplement, c.XactedOn
			,		SectionWt=0, Weight=0
			from	acct.Ledger#Raw()          x
			cross	apply core.Matter#Type()   k
			join	core.Matter#Raw()          m on m.ID=x.MatterID and m.Type =k.AssortedFees
			join	acct.Vault#Raw()           v on x.PartyID=v.PartyID and x.CurrencyID=v.CurrencyID
			join	acct.VaultXact#Raw()       c on c.VaultID=v.ID and c.InvoiceID=x.InvoiceID
			cross	apply core.Registry#ID()   r 
			join	core.Supplement#Raw()      s on s.RegID =r.AssortedFees and s.RowID=m.ID
			where	x.PartyID in (10983, 10987)
			union all
			select	x.ID, x.PartyID, VaultBal=c.NextBal, x.CurrencyID, x.TalliedOn, ChargeID, ChargeAmt
			,		ClientRefNbr=N'', RefNbr=N'', Supplement, c.XactedOn
			,		SectionWt=0, Weight=0
			from	acct.Ledger#Raw()          x
			cross	apply core.Matter#Type()   k
			join	core.Matter#Raw()          m on m.ID=x.MatterID and m.Type =k.StorageFee
			join	acct.Vault#Raw()           v on x.PartyID=v.PartyID and x.CurrencyID=v.CurrencyID
			join	acct.VaultXact#Raw() c on c.VaultID=v.ID and c.InvoiceID=x.InvoiceID
			cross	apply core.Registry#ID()   r 
			join	core.Supplement#Raw()      s on s.RegID =r.Ledger and s.RowID=x.ID
			where	x.PartyID in (10983, 10987)
			union all
			select	x.ID, x.PartyID, VaultBal=c.NextBal, x.CurrencyID, x.TalliedOn, ChargeID, ChargeAmt
			,		ClientRefNbr=r.Number, RefNbr=p.Number, Supplement=N'', c.XactedOn
			,		SectionWt=Weight, Weight
			from	acct.Ledger#Raw()          x					
			join	shpt.Parcel#Raw()          m on m.ID=x.MatterID 
			join	acct.Vault#Raw()           v on x.PartyID=v.PartyID and x.CurrencyID=v.CurrencyID
			join	acct.VaultXact#Raw()       c on c.VaultID=v.ID and c.InvoiceID=x.InvoiceID
			cross	apply core.RefNbr#Type()   t
			join	core.RefNbr#Raw()          r on r.MatterID=m.ID and r.Type=t.ClientRef
			left	join core.RefNbr#Raw()     p on p.MatterID=m.ID and p.Type=t.PostCourier
			where	x.PartyID in (10983, 10987)
			union all
			select	x.ID, x.PartyID, VaultBal=c.NextBal, x.CurrencyID, x.PaidOn, ChargeID=iif(x.PaidAmt>0, g.Deposit, g.Deduct)
			,		ChargeAmt=x.PaidAmt
			,		ClientRefNbr=N'', RefNbr=N'', Supplement=N'', c.XactedOn
			,		SectionWt=0, Weight=0
			from	acct.Payment#Raw()   x
			join	acct.Vault#Raw()     v on x.PartyID=v.PartyID and x.CurrencyID=v.CurrencyID
			join	acct.VaultXact#Raw() c on c.VaultID=v.ID and c.PaymentID=x.ID
			cross	apply acct.Charge#ID() g
			where	x.PartyID in (10983, 10987)		
				
	)
	select	u.ID, PartyAlias=d.Alias, TalliedOn, ClientRefNbr, CurrencyID, XactedOn
	,		RefNbr, VaultBal, ChargeAmt, Weight, SectionWt,  ChargeID, Supplement	
	from	core.Party#Raw() d
	join	cte              u on d.ID=u.PartyID
	where	d.ID in (10983, 10987)


)
