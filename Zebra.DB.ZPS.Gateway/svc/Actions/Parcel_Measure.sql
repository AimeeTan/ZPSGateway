-- PeterHo, AaronLiu
CREATE PROCEDURE [svc].[Parcel$Measure](@numbersInCsv tvp, @wlwhInCsv tvp, @tenancy tvp, @result tvp out, @number tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@minStage E32,    @maxStage E32;
		select	@minStage=PreMin, @maxStage=CurMax
		from	core.Stage#Boundary();
		
		declare	@matterID I64;
		select	@matterID=MatterID, @number=Number
		from	core.RefNbr#ScanMulti(@numbersInCsv, @minStage, @maxStage);
		/*
		if(@matterID is null)
			execute	shpt.Orphan#Init @numbersInCsv=@numbersInCsv, @tenancy=@tenancy, @matterID=@matterID out, @number=@number out;
		*/
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
		/*
		declare	@actionID I32=(select HubMeasure from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@matterID, @actionID=@actionID, @tenancy=@tenancy;
		*/
		execute	shpt.Parcel#Measure @matterID=@matterID, @tenancy=@tenancy;

		select	@result=@matterID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
