/*
	@slip    = TrackingNbr
	@result  = Triad<ParcelID, StateID, ParcelID/1000000>
*/
-- Smile
CREATE PROCEDURE [hub].[Parcel$SortForRackIn](@slip tvp,  @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		declare	@minStage E32,     @maxStage E32;
		select	@minStage=PreMin, @maxStage=CurMax
		from	core.Stage#Boundary();

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@parcelType E8=(select Parcel from core.Matter#Type()); 

		declare	@matterID I64,  @matterType E8;
		select	@matterID=m.ID, @matterType=m.Type
		from	core.RefNbr#ScanOne(@slip, default, default) x
		join	core.Matter#Raw() m on m.ID=x.MatterID;

		if(@matterType<>@parcelType)
		begin
			declare	@parcelCnt I32=(select count(*) from core.Matter#Raw() where ID=@matterID or PID=@matterID);

			declare	@actionID I32=(select HubMeasure from core.Action#ID());
			declare	@spec core.TransitionSpec;
			insert	@spec select t.* 
			from	core.Matter#Raw()                                x
			cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t
			cross	apply core.State#ID()                            s
			where	(x.PID=@matterID or x.ID=@matterID) and x.StateID=s.TobeRackedIn

			declare	@specCnt I32=(select count(*) from @spec);
			if(@parcelCnt=@specCnt) 
				execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;
		end

		declare	@cartAction I32=(select Cart from core.Action#ID());
		declare	@cartSpec core.TransitionSpec;
		insert	@cartSpec select t.*
		from	shpt.Parcel#Tobe(@matterID, @roleID, @cartAction) t
		execute	core.Matter#TransitBySpec @spec=@cartSpec, @userID=@userID;

		select	@result=t.Tvp 
		from	core.Matter#Raw()        x		
		cross	apply tvp.Triad#Make(x.ID, x.StateID, format(x.ID % 1000000, '000000')) t
		where	x.ID=@matterID;

			
	COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END

