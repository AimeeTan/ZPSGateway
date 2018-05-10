-- Smile
CREATE FUNCTION [svc].[Tenancy$Subtype]
(
	@parentID bigint, @typeToMatch int=0, @levelToBreak int=0
)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with cteParty as
	(
		select	Level=0, x.ID, x.PID, x.Type, x.Alias, x.Source
		from	core.Party#Raw() x
		where	x.ID=@parentID
		UNION	ALL
		select	Level+1, c.ID, c.PID, c.Type, c.Alias, c.Source
		from	cteParty p join core.Party#Raw() c on c.PID=p.ID
		where	(@typeToMatch =0 or c.Type=@typeToMatch)
		and		(@levelToBreak=0 or Level<=@levelToBreak)
	)
	select	ID    =isnull(ID, 0),    Alias=isnull(Alias, ''), PID=isnull(PID, 0)
	,		Type  =isnull(Type, 0),  Level=isnull(Level, 0)
	,		Source=isnull(Source, 0)
	from	cteParty where ID<>@parentID
)