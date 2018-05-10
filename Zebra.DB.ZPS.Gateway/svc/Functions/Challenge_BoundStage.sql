--PeterHo
CREATE FUNCTION [svc].[Challenge$BoundStage]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	b.ID
	from	core.Stage#ID() k cross apply
	(
		select	ID=k.RouteAssigned
		--UNION	ALL
		--select	k.SackMfted
	) b
)
