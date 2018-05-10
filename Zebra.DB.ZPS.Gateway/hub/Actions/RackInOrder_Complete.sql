/*
	@slip    = Many[Duad<RackCode, Comma[ParcelID]> ]
	@context = OrderInID
	@result  = Quad<ID, CreatedOn, CompletedOn, RackedCount>
*/
-- Smile
CREATE PROCEDURE [hub].[RackInOrder$Complete](@slip tvp,  @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32,    @hubID I32;
		select	@userID=UserID, @roleID=RoleID, @hubID=HubID
		from	loc.Tenancy#Of(@tenancy);

		with	cteRack as
		(
			select	RackCode=x.v1, RackID=isnull(ID, 0)
			from	tvp.Duad#Slice(@slip, default, default) x
			left	join whse.Rack#Raw()                    r on r.Code=x.v1 and r.HubID=@hubID
		)
		insert	into whse._Rack(HubID, Code) select	@hubID, RackCode from cteRack where	RackID=0;

		declare	@actionID I32=(select Rack from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* 
		from	tvp.Duad#Slice(@slip, default, default)          x
		cross	apply tvp.I64#Slice(x.v2)                        i
		cross	apply shpt.Parcel#Tobe(i.ID, @roleID, @actionID) t
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		declare	@orderInID I32=(@context);
		with	cteRackedParcel as
		(
			select	RackID=r.ID, ParcelID=i.ID
			from	tvp.Duad#Slice(@slip, default, default) x
			cross	apply tvp.I64#Slice(x.v2)               i
			join	whse.Rack#Raw()                         r on r.Code=x.v1 and r.HubID=@hubID											 
		)
		merge	into shpt._RackXact as o using cteRackedParcel as n
		on		(o.RackID=n.RackID and o.ParcelID=n.ParcelID)
		when	matched		then update set o.OrderInID=@orderInID, o.OrderOutID=0
		when	not matched then insert(  ParcelID,   RackID,  OrderInID, OrderOutID)
								 values(n.ParcelID, n.RackID, @orderInID, 0)
		;
		declare	@rackedCnt I32=(@@rowcount);
		update	whse._RackOrder set CompletedOn=getutcdate() where ID=@orderInID;

		execute	shpt.Parcel#TryRackOut;

		select	@result=t.Tvp from whse.RackOrder#Raw()                           x 
		cross	apply tvp.Quad#Make(x.ID, x.CreatedOn, x.CompletedOn, @rackedCnt) t
		where	ID=@orderInID;

	COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END

