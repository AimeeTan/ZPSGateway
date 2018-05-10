/*
	@result  = Duad<OrderOutID, CreatedOn>
*/
-- Smile, AaronLiu
CREATE PROCEDURE [hub].[RackOutOrder$Init](@tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
	
		declare	@userID I32,    @hubID I32;
		select	@userID=UserID, @hubID=HubID
		from	loc.Tenancy#Of(@tenancy);

		declare	@orderType E8=(select RackOut from whse.Order#Type());
		declare	@id I32, @createdOn DT=(getutcdate());
		select	@id=ID,  @createdOn=CreatedOn
		from	whse.RackOrder#Raw()
		where	RackerID=@userID and OrderType=@orderType and CompletedOn=dbo.DT@Empty();

		if(isnull(@id, 0)=0)
		begin
			execute	whse.RackOrder#Create @id=@id out, @rackerID=@userID, @orderType=@orderType;
			with	cte as
			(
				select	x.ParcelID, x.RackID, x.OrderInID, x.OrderOutID, p.AID
				,		LagAID=lag(p.AID, 1, 0) over(order by x.ParcelID)
				from	shpt.RackXact#Raw()	  x
				join	shpt.Parcel#Base()	  p on p.ID=x.ParcelID
				join	whse.Rack#Raw()		  r on r.ID=x.RackID
				cross	apply core.State#ID() s
				where	r.HubID=@hubID and x.OrderOutID=0 and p.StateID=s.TobeRackedOut
			),	cteMarker as
			(
				select	ParcelID, RackID, OrderInID, OrderOutID
				,		Marker=sum(case when AID=0 or AID<>LagAID then 1 else 0 end) over (order by AID, ParcelID)
				from	cte
			), cteRackOut as
			(
				select	ParcelID, RackID, OrderInID, OrderOutID
				from	cteMarker
				where	Marker<101
			)
			update	cteRackOut set OrderOutID=@id;
			declare	@expectedCnt int=(@@rowcount);
			if (@expectedCnt=0)
				delete	from whse._RackOrder where ID=@id;
		end

		select	@result=Tvp from tvp.Duad#Make(@id, @createdOn);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END