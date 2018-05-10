--Eason
CREATE FUNCTION [svc].[Setting$ByName](@name tvp)
RETURNS TABLE
--WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	Value
	from	core.Setting#Raw()
	where	Name=@name
)