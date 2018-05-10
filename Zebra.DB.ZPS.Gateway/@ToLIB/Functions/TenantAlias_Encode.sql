--Smile.Wang
CREATE FUNCTION [loc].[TenantAlias#Encode](@alias varchar(40) )
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	TenantAlias=concat(@alias, ' (Admin)')
)
