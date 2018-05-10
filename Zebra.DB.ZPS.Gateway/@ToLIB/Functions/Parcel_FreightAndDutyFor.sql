--Smile
CREATE FUNCTION [shpt].[Parcel#FreightAndDutyFor](@parcelIDs dbo.I64Array readonly)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	MatterID=x.ID, ContractID, [LedgerPartyID]=p.AID, u.ChargeID, u.ChargeAmt, u.CurrencyID
	from	shpt.Parcel#Base() x
	join	core.Party#Raw()   p on p.ID=x.SiteID
	cross	apply core.RefInfo#Type() k
	outer	apply core.RefInfo#Of(x.ID, k.BrokerageInfo) i
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
		from	brkg.DutyRate#For(p.AID, t.ClrMethodID, i.Info)          r
		UNION	ALL
		select	r.DutyRate, ChargeID=g.BrokerageFee, r.CurrencyID
		from	brkg.BrokerageFee#For(x.RouteID, i.Info)                 r
	) u
	where	x.ID in (select ID from @parcelIDs)	and u.ChargeAmt>0
)
