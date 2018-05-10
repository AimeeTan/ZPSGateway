-- Eva
CREATE FUNCTION [zeb].[Challenge$Tvp](@matterID bigint)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Challenges from core.Challenge#Tvp(@matterID)
)