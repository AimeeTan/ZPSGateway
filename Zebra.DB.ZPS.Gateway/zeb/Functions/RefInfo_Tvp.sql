-- Eva
CREATE FUNCTION [zeb].[RefInfo$Tvp](@matterID bigint)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	RefInfos from core.RefInfo#Tvp(@matterID)
)