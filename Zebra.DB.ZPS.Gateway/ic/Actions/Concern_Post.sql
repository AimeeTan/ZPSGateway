/*
@slip=Duad<Comma[AddedConcernType], Comma[DeletedConcernType]>
@context=MatterID
*/
--Smile
CREATE PROCEDURE [ic].[Concern$Post](@slip tvp, @context tvp)
WITH ENCRYPTION
AS
BEGIN	
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

	declare	@addedConcerns tvp, @deletedConcerns tvp, @matterID bigint;
	select	@addedConcerns=v1,  @deletedConcerns=v2,  @matterID=@context
	from	tvp.Duad#Of(@slip, default);

	execute	core.Concern#Add	@matterID=@matterID, @concerns=@addedConcerns;
	execute	core.Concern#Remove @matterID=@matterID, @concerns=@deletedConcerns;

	update	core._Matter set HandlerID=0 where ID=@matterID;

COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END