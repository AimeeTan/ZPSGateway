/*
@slip    = idsInCsv;
@context = Quad<RcvHubID, POA, MawbNbr, LocalOutgatedOn>;
@result  = ParcelCnt
*/
--Smile
CREATE PROCEDURE [svc].[HubManifest$ImportToSurrender](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@parcelCnt int=(select count(*) from tvp.I64#Slice(@slip));
		declare	@validCnt int;
		declare	@actionID  I32=(select ImportHubManifest from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from tvp.I64#Slice(@slip)      x
		cross	apply shpt.Parcel#Maybe(ID, @roleID, @actionID) t;
		select	@validCnt=@@ROWCOUNT;

		if(@parcelCnt>@validCnt)
			execute dbo.Assert#Fail @msg=N'Please Check the Parcel Stage.';

		declare	@now       DT=getutcdate();
		declare	@stateID   I32=(select SackMftSurrendered from core.State#ID());		
		declare	@source    E8=(select  InfoPath from core.Source#ID());	
		declare	@type      E8=(select  SackMft  from core.Matter#Type());
		declare	@stage     E32=(select Stage    from core.Stage#Of(@stateID));
		declare	@sackMftID I64=next value for core.MatterSeq;
		declare	@hubID int,  @utcOffset smallint, @utcTime DT;
		select	@hubID=x.v1, @utcOffset=t.UtcOffset
		,		@utcTime=dateadd(hour, -t.UtcOffset, x.v4)
		from	tvp.Quad#Of(@context, default) x
		join	core.Tenant#Raw()              t on t.ID=cast(x.v1 as int);
	    
		insert	core._Matter
				(ID,         PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		values	(@sackMftID,   @hubID, @stateID, @stage, @source, @type,     @now);

		insert	shpt._SackMft
				(       ID, POD, POA, MawbNbr, FlightNbr)
		select	@sackMftID, '',  v2,  v3,      ''
		from	tvp.Quad#Of(@context, default)

		insert	core._Activity
				(  MatterID,  StateID,  UserID, TalliedOn)
		values	(@sackMftID, @stateID, @userID,      @now);

		insert	core._RefStamp(MatterID,  StateID,  UtcTime,  UtcOffset, UtcPlaceID)
		values	            (@sackMftID, @stateID, @utcTime, @utcOffset, @hubID);
		execute	core.Matter#TransitBySpecWithPID @spec=@spec, @userID=@userID, @pid=@sackMftID;

		declare	@utcStamp tvp=(select Tvp from tvp.Trio#Make(@utcTime, @utcOffset, @hubID));
		execute	core.RefStamp#MergeBySpec @spec=@spec, @utcStamp=@utcStamp;
		
		select	@result=@validCnt;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END