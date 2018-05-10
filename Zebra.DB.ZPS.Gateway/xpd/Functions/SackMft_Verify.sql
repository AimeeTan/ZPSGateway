--	Aimee
CREATE	FUNCTION [xpd].[SackMft$Verify](@mawbNbr char(11), @siteID int)
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	top(1) s.ID, MawbNbr 
	from	shpt.SackMft#Raw() s
	join	core.Matter#Raw()  m on m.PID=s.ID
	where	s.MawbNbr=@mawbNbr and  m.PosterID=@siteID
	order	by s.ID desc
)