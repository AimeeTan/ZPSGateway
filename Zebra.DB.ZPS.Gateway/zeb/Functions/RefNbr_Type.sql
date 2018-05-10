-- Eva
CREATE FUNCTION [zeb].[RefNbr$Type] ()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	MIT
	,		ClientRef
	,		PreCourier
	,		PostCourier
	,		MawbNbr
	,		MblNbr
	,		VenderRef
	from	core.RefNbr#Type()
)