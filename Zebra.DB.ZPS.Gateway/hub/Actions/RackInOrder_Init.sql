/*
	@result  = Duad<OrderInID, CreatedOn>
*/
-- Smile
CREATE PROCEDURE [hub].[RackInOrder$Init](@tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	
		declare	@userID I32  =(select UserID from loc.Tenancy#Of(@tenancy));
		declare	@orderType E8=(select RackIn from whse.Order#Type());
		declare	@id I32;
		execute	whse.RackOrder#Create @id=@id out, @rackerID=@userID, @orderType=@orderType;

		select	@result=Tvp from tvp.Duad#Make(@id, getutcdate());
	
END