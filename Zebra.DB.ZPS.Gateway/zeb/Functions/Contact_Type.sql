-- Eva
CREATE FUNCTION [zeb].[Contact$Type] ()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Billing
	,		Shipping
	,		Returning
	from	core.Contact#Type()
)