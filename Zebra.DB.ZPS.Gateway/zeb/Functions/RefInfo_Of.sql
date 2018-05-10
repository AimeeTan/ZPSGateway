-- Eva
CREATE FUNCTION [zeb].[RefInfo$Of](@matterID bigint, @type tinyint)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Info from core.RefInfo#Of(@matterID, @type)
)