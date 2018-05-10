/*
brokerageInfo=Mucho[Triad<SkuID, CmdyInfo, LineInfo:Localized>]
CmdyInfo     =Quad<CmdyHeadID, CmdyTailID, DutyCode, DutyRate>
LineInfo     =Quad<GoodsInfo, LineQty, LineTotal, CmdyID>
*/
--Smile.Wang
CREATE FUNCTION [tms].[Freight#For](@svcType int, @rcvHubID bigint, @measuredWt real, @brokerageInfo nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with cteFreight as
	(
	select	SvcRate=cast((SvcRate*10000) as float)/10000
	from	tms.SvcRate#For(@svcType, @rcvHubID, @measuredWt)
	UNION	ALL
	select	isnull(cast((c.Surcharge*10000) as float)/10000,0)
	from	tvp.Spr#Const()      k
	cross	apply tvp.Triad#Slice(@brokerageInfo, default, k.Mucho) x
	cross	apply loc.LineInfo#Of(x.v3) q
	join	brkg.Commodity#Raw()        c on c.ID=q.CmdyID
	)

	select Freight=sum(SvcRate) from cteFreight
)
