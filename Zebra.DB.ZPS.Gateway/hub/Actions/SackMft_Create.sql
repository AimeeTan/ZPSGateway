/*
@slip    tvp =Comma[SackID]
@context tvp =Triad<MawbNbr, FlightID, BrokerID>
@result	 tvp =SackMftID
*/
--Smile
CREATE PROCEDURE [hub].[SackMft$Create](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

		declare	@userID I32,    @hubID I32,	  @roleID I32;
		select	@userID=UserID, @hubID=HubID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@mawbNbr char(11), @flightID I64, @flightNbr varchar(30), @poa char(3), @pod char(3), @brokerID I32;
		select	@mawbNbr=v1, @flightID=v2, @flightNbr=FlightNbr, @poa=POA, @pod =POD, @brokerID=v3
		from	tvp.Triad#Of(@context, default) x
		join	tms.Flight#Raw()  f on f.ID=cast(x.v2 as bigint)
		join	core.Matter#Raw() m on m.ID=f.ID
		cross	apply core.State#ID() k
		where	m.StateID=k.FlightBooked;

		declare	@spec core.TransitionSpec,
				@actionID	E32=(select AddToSackMft from core.Action#ID());
		insert	@spec select t.* 
		from	shpt.Sack#Raw() x
		cross	apply core.Matter#Tobe(x.ID, @roleID, @actionID) t
		where	x.ID  in (select ID from tvp.I64#Slice(@slip))
		and		x.BrokerID=@brokerID;

		if (not exists(select * from @spec)) return;

		BEGIN TRY
		BEGIN	TRAN;

	    declare	@sackMftID I64, @exeContext tvp;
		select	@exeContext=Tvp from tvp.Quad#Make(@pod, @poa, @mawbNbr, @flightNbr);

	    execute shpt.SackMft#Create @id=@sackMftID out, @context=@exeContext, @tenancy=@tenancy;

		update	core._Matter set PID=@flightID where ID=@sackMftID;
	    execute core.Matter#CascadeBySpec @spec=@spec, @userID=@userID;

		with cteSack as
		(
			select	ID, PID
			from	core.Matter#Raw() x
			join	@spec c on c.MatterID=x.ID			
		)
		update	cteSack set PID=@sackMftID;

		select	@result=@sackMftID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END