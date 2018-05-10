--PeterHo
CREATE	FUNCTION [svc].[Announcement$For](@source tinyint)
RETURNS	TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID, SourceID, Body
	from	core._Announcement
	where	SourceID=0
	and		EffectiveOn>=GETUTCDATE() and ExpiredOn<GETUTCDATE()
	UNION	ALL
	select	ID, SourceID, Body
	from	core._Announcement
	where	SourceID>0 and SourceID=@source
	and		EffectiveOn>=GETUTCDATE() and ExpiredOn<GETUTCDATE()
)
