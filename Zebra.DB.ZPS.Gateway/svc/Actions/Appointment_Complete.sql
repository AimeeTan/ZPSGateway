/*
@slip		 = Duad<Many<ParcelID>, Triad<Source, StoreSite, Entry[Block<PreCourier, HandWrittenOrderImg>]>>
@context	 = Duad<AppointmentID, HandoverInfo>
HandOverInfo = Duo<HandoverMoney, HandoverImage>
*/
--AaronLiu
CREATE PROCEDURE [svc].[Appointment$Complete](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- 1.	Tranit Appt to Pickedup
		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@appointmentID tvp, @handoverInfo tvp;
		select	@appointmentID =v1, @handoverInfo =v2
		from	tvp.Duad#Of(@context, default);

		declare	@actionID  E32=(select CfmPickedup=17299 from core.Action#ID());	--HACK

		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from core.Matter#TobeVia(@appointmentID, @roleID, @actionID) t
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		-- 2.	Add HandoverInfo
		declare	@handoverSlip tvp;
		select	@handoverSlip=Tvp
		from	core.RefInfo#Type() t
		cross	apply tvp.Triad#Make(@appointmentID, 14/*HACK*/, @handoverInfo);

		execute	core.RefInfo#Merge @slip=@handoverSlip;

		-- 3.	Init HandWrittenOrders
		declare	@normals tvp, @handWrittens tvp;
		select	@normals =v1, @handWrittens =v2
		from	tvp.Duad#Of(@slip, default);

		declare	@handWrittenSlip  tvp, @handWrittenContext   tvp, @handWrittenResult tvp;
		select	@handWrittenSlip=x.v3, @handWrittenContext=d.Tvp
		from	tvp.Triad#Of(@handWrittens, default) x
		cross	apply tvp.Duad#Make(x.v1, x.v2)		 d

		-- TODO: Refine api.Parcel$InitForHandWrittenOrder
		execute	api.Parcel$InitForHandWrittenOrder @slip=@handWrittenSlip, @context=@handWrittenContext, @tenancy=@tenancy, @result=@handWrittenResult out;

		-- 4.	Link Parcels to Appointment
		with	cte as
		(
			select	m.ID, m.AID
			from	core.Matter#Raw() m, tvp.Pair#Of(@handWrittenResult) p
			cross	apply tvp.Comma#Slice(concat(@normals, N',', p.v2))  x
			where	m.ID=cast(x.Piece as bigint) and m.ID>0
		)
		update	cte set AID=@appointmentID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH 
END