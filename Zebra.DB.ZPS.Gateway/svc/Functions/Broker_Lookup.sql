--Smile
CREATE FUNCTION [svc].[Broker$Lookup]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, BrokerAlias
	from	brkg.Broker#Raw()
	where	ID>0
)