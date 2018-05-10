-- AaronLiu
CREATE FUNCTION [core].[RefNbr#Of](@matterID I64, @type E8)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Number
	from	core.RefNbr#Raw()
	where	MatterID=@matterID and Type=@type
)