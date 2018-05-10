-- AaronLiu, PeterHo
CREATE FUNCTION [core].[Matter#NodeDn](@matterID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with ctePNode as
	(
		select	Level=0,       x.ID, x.AID, x.PID, x.Type, x.Source, x.Stage, x.StateID, x.RejoinID
		from	core.Matter#Raw() x
		where	x.ID=@matterID and @matterID>0
		UNION	ALL
		select	Level=Level+1, x.ID, x.AID, x.PID, x.Type, x.Source, x.Stage, x.StateID, x.RejoinID
		from	ctePNode p join core.Matter#Raw() x
		on		x.AID=p.ID
		UNION	ALL
		select	Level=Level+1, x.ID, x.AID, x.PID, x.Type, x.Source, x.Stage, x.StateID, x.RejoinID
		from	ctePNode p join core.Matter#Raw() x
		on		x.PID=p.ID
	)
	select	Level, ID, AID, PID, Type, Source, Stage, StateID, RejoinID from ctePNode
)