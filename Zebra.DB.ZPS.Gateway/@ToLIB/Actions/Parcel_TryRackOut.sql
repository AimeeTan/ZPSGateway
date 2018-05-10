-- AaronLiu
CREATE PROCEDURE [shpt].[Parcel#TryRackOut]
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@slip tvp;
		with	cte(text) as
		(
			select	[text()]=concat(N',', x.ParcelID)
			from	shpt.RackXact#Raw()	  x
			join	core.Matter#Raw()	  m on m.ID=x.ParcelID
			cross	apply core.State#ID() s
			cross	apply shpt.Siblings#Cnt(x.ParcelID)		  c
			cross	apply shpt.Siblings#CntInRack(x.ParcelID) k
			where	x.OrderOutID=0 and c.Cnt=k.Cnt and m.AID>0 and m.StateID=s.RackingRackedIn
			for		xml path(N'')
		)
		select	@slip=Tvp from cte cross apply tvp.Spr#Purify(text, 1);

		declare	@actionID I32=(select QueueRackOut from core.Action#ID())
		,		@userID	  I32=0
		,		@roleID	  I32=0
		,		@spec core.TransitionSpec;
		insert	@spec select t.* from shpt.Parcel#TobeVia(@slip, @roleID, @actionID) t

		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END

