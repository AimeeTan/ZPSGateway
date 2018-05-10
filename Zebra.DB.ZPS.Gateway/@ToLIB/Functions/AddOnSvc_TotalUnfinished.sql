-- Smile
CREATE	FUNCTION [core].[AddOnSvc#TotalUnfinished](@matterID bigint)
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	with cte as
	(
		select	TotalUnfinished=count(*)
		from	core.AddOnSvc#Raw()
		where	MatterID=@matterID and EndedOn=dbo.DT@Empty()	
		union	all
		select	0
	)
	select	top(1) TotalUnfinished from cte
)