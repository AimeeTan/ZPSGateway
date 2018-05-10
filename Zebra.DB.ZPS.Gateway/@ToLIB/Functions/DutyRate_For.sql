/*
brokerageInfo=Mucho[Triad<SkuID, CmdyInfo, LineInfo:Localized>]
CmdyInfo     =Quad<CmdyHeadID, CmdyTailID, DutyCode, DutyRate>
LineInfo     =Quad<GoodsInfo, LineQty, LineTotal, CmdyID>
*/
--Smile.Wang
CREATE FUNCTION [brkg].[DutyRate#For](@partyID int, @clrMethodID int, @brokerageInfo nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with cteDuty as
	(
		select	l.CurrencyID
		,		DutyRateRaw=sum(c.DutyRate*l.LineRawTotal)
		,		ClrRateRaw=sum(d.PercentRate*l.LineRawTotal)
		from	tvp.Spr#Const() k 
		cross	apply tvp.Triad#Slice(@brokerageInfo, default, k.Mucho) x
		cross	apply loc.CmdyInfo#Of(x.v2)       c
		cross	apply loc.LineInfo#Of(x.v3)       l	
		cross	apply brkg.ClrMethodRate#For(@partyID, @clrMethodID) d
		group	by l.CurrencyID		
	)
	, cteTotalDuty as
	(
		select	CurrencyID, DutyRaw=sum(DutyRaw)
		from	
		(
			select	x.CurrencyID, DutyRaw=iif(x.CurrencyID=d.CurrencyID,  iif(DutyRateRaw>d.ExemptionRaw, DutyRateRaw, 0), DutyRateRaw)+ClrRateRaw
			from	cteDuty x
			join	brkg.ClrMethod#Raw() d on d.ID=@clrMethodID
			union	all
			select	CurrencyID, FlatRateRaw
			from	brkg.ClrMethodRate#For(@partyID, @clrMethodID)
		) u
		group by u.CurrencyID
	)
		select	CurrencyID, DutyRate=m.Amt
		from	cteTotalDuty x
		cross	apply dbo.Currency#Encode(x.DutyRaw, CurrencyID) m
)
