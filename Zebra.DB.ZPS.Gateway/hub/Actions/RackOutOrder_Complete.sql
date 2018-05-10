/*
	@slip    = Traid<RackedOutParcels, NotFoundParcels, ExceptionParcels>
	@context = OrderOutID
	@result  = Quad<ID, CreatedOn, CompletedOn, RackedOutCount>
*/
-- Smile, AaronLiu
CREATE PROCEDURE [hub].[RackOutOrder$Complete](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
	
		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@rackedOutParcels tvp, @notFoundParcels tvp, @exceptionParcels tvp;
		select	@rackedOutParcels =v1, @notFoundParcels =v2, @exceptionParcels =v3
		from	tvp.Triad#Of(@slip, default);

		declare	@actionID I32=11350;--(select Rack from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* 
		from	tvp.I64#Slice(@rackedOutParcels) x
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t;
		declare	@rackedOutCount int=(@@rowcount);
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		with	cte as
		(
			select	r.ParcelID, r.OrderOutID
			from	tvp.I64#Slice(concat(@notFoundParcels,N',',@exceptionParcels)) x
			join	shpt.RackXact#Raw() r on x.ID=r.ParcelID
		)
		update	cte set OrderOutID=0;
		update	whse._RackOrder set CompletedOn=getutcdate() where ID=cast(@context as int);

		select	@result=Tvp
		from	whse.RackOrder#Raw() x
		cross	apply tvp.Quad#Make(x.ID, x.CreatedOn, x.CompletedOn, @rackedOutCount)
		where	x.ID=cast(@context as int)
	
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END