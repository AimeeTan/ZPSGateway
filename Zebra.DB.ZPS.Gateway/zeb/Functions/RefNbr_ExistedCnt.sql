--Eva
CREATE FUNCTION [zeb].[RefNbr$ExistedCnt](@nbrsInCsv tvp, @minStage int=100, @maxStage int=25500)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Type, MatchedCnt
	from	core.RefNbr#MatchMulti(@nbrsInCsv, @minStage, @maxStage) x
)
