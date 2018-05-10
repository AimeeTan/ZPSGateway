-- AaronLiu
CREATE FUNCTION [core].[Matter#ANodeDn](@matterID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with ctePNode as
	(
		select	Level=0,       x.ID, x.AID, x.Type, x.Source, x.Stage, x.StateID
		from	core.Matter#Raw() x
		where	x.ID=@matterID and @matterID>0
		UNION	ALL
		select	Level=Level+1, x.ID, x.AID, x.Type, x.Source, x.Stage, x.StateID
		from	ctePNode p join core.Matter#Raw() x
		on		x.AID=p.ID
	)
	select	Level, ID, AID, Type, Source, Stage, StateID from ctePNode
)