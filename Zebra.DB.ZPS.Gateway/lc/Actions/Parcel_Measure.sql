/*
	@slip	= Duad[TrackingNbr, Quad<Weight,Length,Width,Height>]
	@result = Triad<RampCode, RouteCode, Stage>
*/
-- AaronLiu
CREATE PROCEDURE [lc].[Parcel$Measure](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		-- Should Stage between PreMin and CurMax?
		declare	@minStage E32,    @maxStage E32;
		select	@minStage=PreMin, @maxStage=Ended
		from	core.Stage#Boundary();

		declare	@number varchar(40), @weight real, @length real, @width real, @height real;
		select	@number=x.v1,		 @weight=q.v1, @length=q.v2, @width=q.v3, @height=q.v4
		from	tvp.Duad#Of(@slip, default)		 x
		cross	apply tvp.Quad#Of(x.v2, default) q
		
		declare	@matterID I64;
		select	@matterID=MatterID
		from	core.RefNbr#ScanOne(@number, @minStage, @maxStage);

		declare	@rcvHubID I32,   @userID I32;
		select	@rcvHubID=HubID, @userID=UserID
		from	loc.Tenancy#Of(@tenancy);
		execute	core.Activity#OnceHubAccepted @matterID=@matterID, @userID=@userID;

		update	shpt._Parcel 
		set		RcvHubID=@rcvHubID, Weight=@weight, Length=@length
		,		Width=@width,		Height=@height
		where	ID=@matterID;
		
		declare	@code I16;
		select	@code=(select Code from shpt.Parcel#PreSorting(@matterID));
		if(@code is null)
		begin
			execute	shpt.Parcel#Measure @matterID=@matterID, @tenancy=@tenancy;
			select	@code=Code from shpt.Parcel#Sorting(@matterID);
		end

		select	@result=t.Tvp
		from	shpt.Parcel#Deep() x
		cross	apply tvp.Triad#Make(@code, x.RouteCode, x.Stage) t
		where	x.ID=@matterID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END