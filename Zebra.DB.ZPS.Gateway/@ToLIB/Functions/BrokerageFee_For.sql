/*
brokerageInfo=Mucho[Triad<SkuID, CmdyInfo, LineInfo:Localized>]
CmdyInfo     =Quad<CmdyHeadID, CmdyTailID, DutyCode, DutyRate>
LineInfo     =Quad<GoodsInfo, LineQty, LineTotal, CmdyID>
*/
--Smile.Wang
CREATE FUNCTION [brkg].[BrokerageFee#For](@routeID int,  @brokerageInfo nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with creRate as
	(
		select	l.CurrencyID
		,		BrokerageFee=ceiling(sum(x.PercentRate*l.LineDecTotal)*100)/100
		from	tms.Route#Raw()       u
		join	brkg.Broker#Raw()     x on u.BrokerID=x.ID
		cross	apply tvp.Spr#Const() k
		cross	apply tvp.Triad#Slice(@brokerageInfo, default, k.Mucho) t
		cross	apply loc.CmdyInfo#Of(t.v2)                             c
		cross	apply loc.LineInfo#Of(t.v3)                             l	
		where	u.ID=@routeID
		group	by l.CurrencyID	
	)
		select	CurrencyID, DutyRate=m.Amt
		from	creRate x
		cross	apply dbo.Money#Make(x.BrokerageFee, x.CurrencyID) m
		where	m.Amt>x.CurrencyID
)
