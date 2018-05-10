--Eva
CREATE PROCEDURE [zeb].[OutboundQ$Dequeue](@source E8, @qtype E8=0, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out
END
