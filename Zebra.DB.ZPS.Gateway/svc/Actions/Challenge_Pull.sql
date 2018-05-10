/*
@slip    = Many[Duad<MatterID, ChallengeType>]
@context = MessageBody
*/
--Aimee
Create PROCEDURE [svc].[Challenge$Pull](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION--
AS
BEGIN
	SET NOCOUNT	ON;

	execute	core.Challenge#Pull @slip=@slip, @context=@context, @tenancy=@tenancy;
END