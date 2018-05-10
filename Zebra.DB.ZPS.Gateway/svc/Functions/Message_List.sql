--PeterHo: HACK!!， Aimee
CREATE	FUNCTION [svc].[Message$List](@matterID bigint)
RETURNS	TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	m.ID, m.AuxID, m.Body, m.PostedOn, m.PosterID, m.PosterAlias, BoundStage=isnull(cast(c.BoundStage as int), 0)
	from	core.Registry#ID() k
	cross	apply core.Message#Of(k.Matter, @matterID, default) m
	left	join core.Challenge#Of(@matterID) c on c.Type=m.AuxID and c.Body=m.Body and c.PostedOn=m.PostedOn
)
