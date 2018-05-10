-- JimQiu, Smile, AaronLiu
CREATE PROCEDURE [api].[Activity$Subscribe](@mic varchar(40), @refNbr varchar(16))
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@matterID I64=(select MatterID from core.MIC#IdOf(@mic));

		insert	api._ActivitySubscription
		(		 MatterID,  RefNbr) 
		values(	@matterID, @refNbr)

		insert	core._OutboundQ select ToSource, QueueType, dateadd(millisecond, 10, QueuedOn), x.MatterID, StateID 
		from	core.Queue#OutboundX()    x
		cross	apply core.Queue#Type()   k
		where	x.MatterID=@matterID
		and		x.QueueType=k.SubscribeCallback 
		and		x.QueuedOn<GETUTCDATE()

		declare	@source E8=(select InfoPath from core.Source#ID())
		,		@qtype	E8=(select SubscriberRegister=207 from core.Queue#Type()); --HACK
		execute	core.OutboundQ#Enqueue @source=@source, @qtype=@qtype, @matterID=@matterID, @stateID=0;
	
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
