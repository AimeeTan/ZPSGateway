-- Eva
CREATE FUNCTION [zeb].[Matter$Raw]()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	m.*
	from	core.Matter#Raw() m
)