--Daxia
CREATE FUNCTION [tms].[ZoneCode#For](@zoneCode varchar(10))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ZoneCode=@zoneCode
	,		Zip3=left(@zoneCode, 3)
	,		Plus2=substring(@zoneCode, 4, 2)
)
