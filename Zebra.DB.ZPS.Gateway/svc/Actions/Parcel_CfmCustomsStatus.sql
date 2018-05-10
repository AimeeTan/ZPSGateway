/*
@slip    tvp=at.Tvp.Comma.Join(TrackingNbrs);
@context tvp=at.Tvp.Triad.Join(ActionID, POA, at.Tvp.Trio.Join(UtcTime, UtcOffset, UtcPlaceID));
*/
--Smile, PeterHo
CREATE PROCEDURE [svc].[Parcel$CfmCustomsStatus](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@minStage E32,       @maxStage E32;
		select	@minStage=Outgated, @maxStage=Surrendered
		from	core.Stage#ID();

		declare	@actionID I32,  @poa char(3), @utcStamp tvp;
		select	@actionID=x.v1, @poa=x.v2,    @utcStamp=x.v3
		from	tvp.Triad#Of(@context, default) x

		declare @ids I64Array;
		insert	@ids select distinct MatterID
		from	loc.RefNbr#Slice(@slip) x
		cross	apply core.RefNbr#ScanOne(x.Number, @minStage, @maxStage) r
		join	shpt.Parcel#Raw() p on p.ID=r.MatterID		
		where	p.POA=@poa;


		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);
		
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @ids
		cross	apply shpt.Parcel#Tobe(ID, @roleID, @actionID) t;

		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;
		execute	core.RefStamp#MergeBySpec @spec=@spec, @utcStamp=@utcStamp;

		select	@result=(select count(*) from @ids);

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END