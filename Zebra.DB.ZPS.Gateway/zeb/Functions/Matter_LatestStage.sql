/*
	TODO: refine this, with offset cannot use calendar offset
*/
-- AaronLiu
CREATE FUNCTION [zeb].[Matter$LatestStage](@matterID I64, @startDate DT, @endDate DT)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	LatestStage=isnull(max(s.Stage),0)
	from	core.Matter#PNodeUp(@matterID) x
	join	core.Activity#Raw() a on a.MatterID=x.ID
	join	core.State#Raw()    s on s.ID=a.StateID
--	join	dbo.Calendar#Raw()  d on d.Value=cast(a.TalliedOn as Date)
--	cross   apply dbo.Calendar#Of(@startDate) sd
--	cross   apply dbo.Calendar#Of(@endDate  ) ed
--	where	d.DOffset   between sd.DOffset and  ed.DOffset
	where	a.TalliedOn between @startDate and @endDate
)