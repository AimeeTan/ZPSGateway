--Daxia
CREATE FUNCTION [shpt].[SackMft#LedgerByCharge](@sackMftID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	MatterID=x.ID, ContractID=0, [LedgerPartyID]=p.AID, u.ChargeID, u.ChargeAmt, u.CurrencyID
	from	shpt.SackMft#Base() x
	join	core.Party#Raw()    p on p.ID=x.HubID
	cross	apply core.RefInfo#Type()                    k
	outer	apply core.RefInfo#Of(x.ID, k.BrokerageInfo) i
	cross	apply acct.Charge#ID()                       g
	cross	apply
	(
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbAMSFiling, 0) r
		cross	apply dbo.Money#Make(iif(r.Rate>r.Minimum, r.Rate, r.Minimum), r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbBaseFee, 0) r
		cross	apply dbo.Money#Make(iif(r.Rate>r.Minimum, r.Rate, r.Minimum), r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbAirlineISCFee, 0) r
		cross	apply dbo.Money#Make(iif(r.Rate>r.Minimum, r.Rate, r.Minimum), r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbCfsTransferFuel, 0) r
		cross	apply dbo.Money#Make(iif(r.Rate>r.Minimum, r.Rate, r.Minimum), r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbCfsTransferFee, 0) r
		cross	apply dbo.Money#Make(iif(r.Rate>r.Minimum, r.Rate, r.Minimum), r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbSectionEntryFee, 0) r
		cross	apply shpt.SackMft#MawbWtRateCalc(r.Rate, x.MawbWt, 1, r.Minimum) mc
		cross	apply dbo.Money#Make(mc.MawbWtAmt, r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbTerminalTransfer, 0) r
		cross	apply shpt.SackMft#MawbWtRateCalc(r.Rate, x.MawbWt, 1, r.Minimum) mc
		cross	apply dbo.Money#Make(mc.MawbWtAmt, r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbPickUpCharge, 0) r
		cross	apply shpt.SackMft#MawbWtRateCalc(r.Rate, x.MawbWt, 1, r.Minimum) mc
		cross	apply dbo.Money#Make(mc.MawbWtAmt, r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.MawbPalletizing, 0) r
		cross	apply shpt.SackMft#MawbWtRateCalc(r.Rate, x.MawbWt, 150, r.Minimum) mc
		cross	apply dbo.Money#Make(mc.MawbWtAmt, r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.HawbBrkgFee, 0) r
		cross	apply shpt.SackMft#HawbCntRateCalc(x.ID, r.Rate, r.Minimum, 1000) hc
		cross	apply dbo.Money#Make(hc.HawbAmt, r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.HawbBrkgLessthanFee, 0) r
		cross	apply shpt.SackMft#HawbCntRateCalc(x.ID, r.Rate, r.Minimum, 1000) hc
		cross	apply dbo.Money#Make(hc.HawbAmt, r.CurrencyID) c
		UNION	ALL
		select	ChargeAmt=c.Amt,  ChargeID=r.ChargeID, r.CurrencyID
		from	tms.SvcCharge#For(x.HubID, x.BrokerID, x.POA, g.HawbHandlingFee, 0) r
		cross	apply shpt.SackMft#HawbCntRateCalc(x.ID, r.Rate, r.Minimum, 5000) hc
		cross	apply dbo.Money#Make(hc.HawbAmt, r.CurrencyID) c
	) u
	where	x.ID in (@sackMftID) and u.ChargeAmt>0
)
