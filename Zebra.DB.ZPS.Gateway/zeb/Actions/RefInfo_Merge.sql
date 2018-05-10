--AaronLiu
CREATE PROCEDURE [zeb].[RefInfo$Merge](@slip nvarchar(max))
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	
	execute	core.RefInfo#Merge @slip=@slip;
END