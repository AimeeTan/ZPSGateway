--AaronLiu
CREATE FUNCTION [svc].[Contact$List]()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID, PartyID, Type, IsDefault, Tvp
	from	core.Contact#Tvp()
)