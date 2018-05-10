-- Eva
CREATE FUNCTION [zeb].[RefNbr$Tvp](@matterID bigint)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	RefNbrs from core.RefNbr#Tvp(@matterID)
)