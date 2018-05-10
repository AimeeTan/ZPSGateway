--Eva
CREATE PROCEDURE [zeb].[RefNbr$Merge](@slip nvarchar(max))
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	
	execute	core.RefNbr#Merge @slip=@slip;
END