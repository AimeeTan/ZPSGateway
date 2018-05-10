-- AaronLiu
CREATE FUNCTION [zeb].[Stage$ID]()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	HubCheckedIn
	from	core.Stage#ID()
)
