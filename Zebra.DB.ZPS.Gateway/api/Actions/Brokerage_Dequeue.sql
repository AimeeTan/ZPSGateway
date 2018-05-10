-- Eason
CREATE PROCEDURE [api].[Brokerage$Dequeue](@source tinyint, @qtype tinyint, @result tvp out)
AS
BEGIN
	SET NOCOUNT ON;

	execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out;
END