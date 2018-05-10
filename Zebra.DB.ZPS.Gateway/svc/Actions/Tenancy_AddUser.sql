/*
@slip   =at.Tvp.Field.Join(PID, AID, Alias, Contact, UserRoles)
@context=Source
*/
--Smile
CREATE PROCEDURE [svc].[Tenancy$AddUser](@slip tvp, @context tvp, @result tvp out)
WITH ENCRYPTION--
AS
BEGIN
	SET NOCOUNT ON;

	declare	@id I64, @type E32=(select Operator from core.Party#Type());
	exec	core.User#Add @id=@id out, @source=@context, @type=@type, @slip=@slip;
	select	@result=@id;
END