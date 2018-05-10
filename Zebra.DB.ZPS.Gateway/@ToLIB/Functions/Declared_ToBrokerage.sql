/*
	@declaredInfo = Mucho[LineInfo]
	@cmdyInfos	  = Mucho[CmdyInfo]
*/
-- AaronLiu
CREATE FUNCTION [loc].[Declared$ToBrokerage](@declaredInfo nvarchar(max), @cmdyInfos nvarchar(max)=N'')
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN
(
	with cte(text) as
	(
		select	[text()]=concat(k.Mucho, b.Tvp)
		from	tvp.Mucho#Slice(@declaredInfo)			    x
		left	join  tvp.Mucho#Slice(@cmdyInfos)			d on x.Seq=d.Seq
		cross	apply tvp.Quad#Make( N'0', N'0', N'', N'0') c
		cross	apply tvp.Triad#Make(N'0', isnull(d.Piece,  c.Tvp), x.Piece) b
		cross	apply tvp.Spr#Const() k 
		order	by x.Seq 
		for		xml path(N'')
	)
	select BrokerageInfo=Tvp from cte cross apply tvp.Spr#Purify(text, default)
)

/*
--AaronLiu
CREATE FUNCTION [loc].[Declared$ToBrokerage](@declaredInfo nvarchar(max))
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN
(
	with cte(text) as
	(
		select	[text()]=concat(k.Mucho, b.Tvp)
		from	tvp.Mucho#Slice(@declaredInfo)			    x
		cross	apply tvp.Quad#Make( N'0', N'0', N'', N'0') c
		cross	apply tvp.Triad#Make(N'0', c.Tvp, x.Piece)  b
		cross	apply tvp.Spr#Const() k 
		order	by x.Seq for xml path (N'')
	)
	select BrokerageInfo=Tvp from cte cross apply tvp.Spr#Purify(text, default)
)
*/