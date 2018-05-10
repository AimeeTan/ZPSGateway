-- Aimee
CREATE FUNCTION core.Message#Tvp(@matterID bigint)
RETURNS TABLE
--, ENCRYPTION
WITH SCHEMABINDING
AS RETURN 
(
	with	cte(text) as
	(
		select	[text()] = concat(k.Many, x.AuxID, k.Quad, x.PosterAlias, k.Quad, x.PostedOn, k.Quad, x.Body)
		from	core.Registry#ID()    m
		cross	apply core.Message#Of(m.Matter, @matterID, default) x
		cross	apply tvp.Spr#Const() k
		for		xml path(N'')
	)
	select	Messages=Tvp from cte cross apply tvp.Spr#Purify(text, default)
)