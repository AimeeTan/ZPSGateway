-- Smile, PeterHo
CREATE FUNCTION [svc].[Account$Lookup]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with cte as
	(
		select	AID from core.Party#Raw()
		where	AID>1 group by AID
	)
	select	ID, Source, Type, Alias
	from	cte x join core.Party#Raw() p on p.ID=x.AID
	where	p.AID>1    -- eliminate Zebra's Hubs
	and		p.Source>0 -- eliminate Virtuals (Port, ...)
	
/*
	select	ID=p.AID, y.Alias
	from	core.Party#Raw()  p
	join	core.Party#Raw()  y on y.ID=p.AID
	cross	apply core.Party#Boundary() b
	where	p.AID>0 and p.Type between 	b.UserMin and b.Tenant
*/
)