--Ken
CREATE FUNCTION [svc].[MftGroup$Lookup]()
RETURNS TABLE
WITH SCHEMABINDING--,ENCRYPTION
AS RETURN
(
	select	MftGroup from tms.Route#Raw() r
	where	r.ID>0   group by MftGroup
)


