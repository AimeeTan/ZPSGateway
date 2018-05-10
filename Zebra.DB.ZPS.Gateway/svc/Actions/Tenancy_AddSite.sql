/*
@slip = Field<PID, AID, Alias, Contact, UtcPlace, UtcOffset>
        Contact=Many[Duad<type, ContactTvp>]
@context=Source
*/
--Smile
CREATE PROCEDURE [svc].[Tenancy$AddSite](@slip tvp, @context tvp, @result tvp out)
WITH ENCRYPTION--
AS
BEGIN
	SET NOCOUNT ON;

	declare	@id I64, @type E32=(select TenantSite from core.Party#Type());
	exec	core.Tenant#Add @id=@id out, @source=@context, @type=@type, @slip=@slip;
	select	@result=@id;
END