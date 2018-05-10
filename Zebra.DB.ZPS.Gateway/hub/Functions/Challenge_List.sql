-- Aimee
CREATE FUNCTION hub.Challenge$List(@number varchar(40))
RETURNS TABLE
--, ENCRYPTION
WITH SCHEMABINDING
AS RETURN 
(
	select	ID=x.MatterID, Messages, Challenges
	from	core.MIC#IdOf(@number) x
	cross	apply core.Message#Tvp(x.MatterID)
	cross	apply core.Challenge#Tvp(x.MatterID)
)