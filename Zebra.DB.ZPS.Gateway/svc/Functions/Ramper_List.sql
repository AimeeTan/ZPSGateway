--AaronLiu
CREATE FUNCTION [svc].[Ramper$List]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.Alias
	from	core.Party#Type() t, core.User#Raw() x
	join	core.Party#Raw()  p on x.ID=p.ID
	where	p.Type=t.Ramper
)