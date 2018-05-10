--Sam
CREATE FUNCTION [svc].[ClrMethod$BrokerLookup]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	c.CountryCode	as CountryCode
		,	b.ID			as BrokerID
		,	b.BrokerAlias	
		,	c.ID			as ClrMethodID
		,	c.ClrMethodCode 
	from	tms.Route#Raw()      r
	join	brkg.Broker#Raw()    b	on b.ID = r.BrokerID
	join	brkg.ClrMethod#Raw() c	on c.ID = r.ClrMethodID
	Where	b.ID > 0 and c.ID > 0
)