-- Ken
CREATE FUNCTION [co].[Payment$Verify](@paymentID bigint)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	select	XID 
	from	acct.Payment#Raw()
	where	ID=@paymentID
)
