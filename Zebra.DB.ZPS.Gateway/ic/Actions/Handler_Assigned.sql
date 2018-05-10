/*
@slip  =Comma[ParcelID]  
@context= UserID
*/
--Smile
CREATE PROCEDURE [ic].[Handler$Assigned](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;

		declare	@userID I32; select @userID=UserID from	loc.Tenancy#Of(@tenancy);
		with cteMatter as
		(
			select	m.ID, HandlerID
			from	tvp.I64#Slice(@slip) x
			join	core.Matter#Raw()    m on m.ID=x.ID
			where	HandlerID IN (0, @userID)
		)
		update	cteMatter set HandlerID=@context;
		
END
