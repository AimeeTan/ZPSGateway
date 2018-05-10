-- AaronLiu
CREATE FUNCTION [hub].[Trucker$List]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID, Alias
	from	tms.Trucker#Raw()
)