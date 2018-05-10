--Sam
CREATE FUNCTION [svc].[ClrMethod$Lookup]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, ClrMethodCode, CountryCode
	from	brkg.ClrMethod#Raw()
)