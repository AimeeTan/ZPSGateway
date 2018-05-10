--Smile
CREATE FUNCTION [shpt].[Parcel#LedgerForVmi](@parcelIDs dbo.I64Array readonly)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	MatterID=x.ID, ContractID, [LedgerPartyID]=p.AID, u.ChargeID, u.ChargeAmt, u.CurrencyID
	from	shpt.Parcel#Base() x
	join	core.Party#Raw()   p on p.ID=x.SiteID
	cross	apply core.RefInfo#Type() k
	outer	apply core.RefInfo#Of(x.ID, k.BrokerageInfo) i
	cross	apply core.RefInfo#Of(x.ID, k.DeclaredInfo)  o
	join	tms.SvcType#Raw()  t on t.ID=x.SvcType
	cross	apply acct.Charge#ID()                                       g
	cross	apply
	(
		select	ChargeAmt=c.Amt,  ChargeID=g.Freight, t.CurrencyID		
		from	tms.Freight#For(x.SvcType, x.RcvHubID, x.Weight, i.Info) r
		cross	apply dbo.Money#Make(r.Freight, t.CurrencyID)            c		
		where	t.ID=x.SvcType
		UNION	ALL
		select	r.DutyRate, ChargeID=g.Duty, r.CurrencyID
		from	brkg.DutyRate#For(p.AID, t.ClrMethodID, i.Info)         r
		where	r.DutyRate>r.CurrencyID
		UNION	ALL
		select	m.Amt, CharegeID=g.OutPkgFee, s.CurrencyID
		from	whse.StorageRate#For(x.RcvHubID, x.SiteID)              s
		cross	apply dbo.Money#Make(s.OutPkgFee, s.CurrencyID)         m
		where	m.Amt>s.CurrencyID
		UNION	ALL
		select	m.Amt, CharegeID=g.OverWeightFee, s.CurrencyID
		from	whse.StorageRate#For(x.RcvHubID, x.SiteID)              s
		cross	apply dbo.Money#Make(s.OverWeightFee, s.CurrencyID)     m
		where	x.Weight>s.WeightLimit
		and		m.Amt>s.CurrencyID
		UNION	ALL
		select	m.Amt, CharegeID=g.ExcessItemsFee, s.CurrencyID
		from	whse.StorageRate#For(x.RcvHubID, x.SiteID)              s
		cross	apply dbo.Money#Make(s.ExcessItemsFee, s.CurrencyID)    m
		cross	apply loc.TotalSkuQty#For(o.Info)                       o
		where	o.TotalSkuQty>s.ItemsQtyLimit	
		and		m.Amt>s.CurrencyID
	) u
	where	x.ID in (select ID from @parcelIDs)	
)
