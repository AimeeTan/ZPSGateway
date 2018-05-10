-- AaronLiu
CREATE PROCEDURE [auto].[Parcel$Measure](@numbersInCsv tvp, @wlwhInCsv tvp, @tenancy tvp, @result tvp out)
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
		
		declare	@matterID I64;
		select	@matterID=MatterID
		from	core.RefNbr#ScanMulti(@numbersInCsv, @minStage, @maxStage);

		declare	@rcvHubID I32,   @userID I32;
		select	@rcvHubID=HubID, @userID=UserID
		from	loc.Tenancy#Of(@tenancy);
		execute	core.Activity#OnceHubAccepted @matterID=@matterID, @userID=@userID;

		with cteParcel as
		(
			select	ID, q.v1,   q.v2,   q.v3,  q.v4
			from	tvp.Quad#Of(@wlwhInCsv, N',') q
			,		shpt.Parcel#Raw() where ID=@matterID
		)
		update	o set RcvHubID=@rcvHubID, Weight=v1, Length=v2, Width=v3, Height=v4
		from	shpt._Parcel o join cteParcel n on o.ID=n.ID;
		
		select	@result=(select Code from shpt.Parcel#PreSorting(@matterID));
		if(@result is null)
		begin
			execute	shpt.Parcel#Measure @matterID=@matterID, @tenancy=@tenancy;
			select	@result=Code from shpt.Parcel#Sorting(@matterID);
		end

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END