--Smile
CREATE	FUNCTION [svc].[Port$List]()
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	Code, UtcOffset, UtcPlaceID
	from	core.Port#Raw()
)
