/*
@slip    tvp=at.Tvp.Duad.join(at.Tvp.Comma.Join(heldTrackingNbrs), at.Tvp.Comma.Join(seizedTrackingNbrs));
@context tvp=at.Tvp.Duad.join(sackMftID, at.Tvp.Trio.Join(UtcTime, UtcOffSet, UtcPlaceID));
*/
--Smile, PeterHo
CREATE PROCEDURE [svc].[SackMft$Release](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;
	    
		declare	@helds tvp,  @seizeds tvp,  @sackMftID I64,  @utcStamp tvp;
		select  @helds=x.v1, @seizeds=x.v2, @sackMftID=s.v1, @utcStamp=s.v2
		from	tvp.Duad#Of(@slip, default)          x
		cross	apply tvp.Duad#Of(@context, default) s

		declare	@ignored tvp, @poa char(3)=(select POA from shpt.SackMft#Raw() where ID=@sackMftID);
		declare	@heldActionID I32,            @seizedActionID I32,              @clearedActionID I32;
		select	@heldActionID=CfmCustomsHeld, @seizedActionID=CfmCustomsSeized, @clearedActionID=CfmCustomsCleared
		from	core.Action#ID();

		declare @heldContext  tvp=(select Tvp from tvp.Triad#Make(@heldActionID, @poa, @utcStamp));
		execute	svc.Parcel$CfmCustomsStatus @slip=@helds, @context=@heldContext, @tenancy=@tenancy, @result=@ignored out;

		declare	@seizedContext  tvp=(select Tvp from tvp.Triad#Make(@seizedActionID, @poa, @utcStamp));
		execute	svc.Parcel$CfmCustomsStatus @slip=@seizeds, @context=@seizedContext, @tenancy=@tenancy, @result=@ignored out;

		declare	@sackMftSlip tvp=(select Tvp from tvp.Duad#Make(@clearedActionID, @utcStamp));
		execute	svc.SackMft$Transit @slip=@sackMftSlip, @context=@sackMftID, @tenancy=@tenancy;

		with cteResult as
		(
			select	Stage, StageCnt=count(*)
			from	core.Matter#PNodeDn(@sackMftID) x
			cross	apply core.Matter#Type()        t
			where	x.Type=t.Parcel
			group	by Stage
		)
		, cte (text) as
		(
			select	[text()]=concat(k.Many, Stage, k.Duad, StageCnt)
			from	cteResult, tvp.Spr#Const() k for xml path(N'')
		)
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, default);
	
		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END