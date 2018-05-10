/*
@slip    = Duad<Comma[AddedParceID], Comma[RemovedParceID]>
@context = Duad<SackID, Weight>
*/
--Smile
CREATE PROCEDURE [hub].[Sack$ReBag](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
		BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @hubID I32,	  @roleID I32;
		select	@userID=UserID, @hubID=HubID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@addedParcelIDs tvp, @deletedParcelIDs tvp;
		select	@addedParcelIDs=v1, @deletedParcelIDs=v2
		from	tvp.Duad#Of(@slip, default)

		declare	@sackID I64, @sackWt float, @brokerID I32, @clrMethodID I32, @poa char(3);
		select	@sackID=v1, @sackWt=v2, @brokerID=BrokerID, @clrMethodID=ClrMethodID, @poa=POA
		from	tvp.Duad#Of(@context, default) x
		join	shpt.Sack#Raw() s on s.ID=cast(x.v1 as bigint);

		declare	@addActionID	I32=(select AddParcelToSack		 from core.Action#ID()),
				@deletedActionID I32=(select RemoveParcelFromSack from core.Action#ID()),
				@addedSpec core.TransitionSpec, @deletedSpec core.TransitionSpec;

		insert	into @deletedSpec select t.*
		from	shpt.Parcel#TobeVia(@deletedParcelIDs, @roleID, @deletedActionID) t;

		insert	into @addedSpec select t.*
		from	shpt.Parcel#Raw() x
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @addActionID) t
		where	x.ID  in (select ID from tvp.I64#Slice(@addedParcelIDs))
		and		x.POA=@poa
		and		x.RouteID in (
								select	RouteID 
								from	tms.Route#Raw() 
								where	BrokerID=@brokerID and ClrMethodID=@clrMethodID
							 )

		if(exists (select * from @deletedSpec))
		BEGIN
		execute	core.Matter#TransitBySpec @spec=@deletedSpec, @userID=@userID, @beAffected=1;
		with cteParcel as
		(
			select	ID, PID
			from	core.Matter#Raw() x
			join	@deletedSpec      c on c.MatterID=x.ID			
		)
		update	cteParcel set PID=0;
		END

		if(exists (select * from @addedSpec))
		BEGIN
		execute	core.Matter#TransitBySpec @spec=@addedSpec, @userID=@userID, @beAffected=1;
		with cteParcel as
		(
			select	ID, PID
			from	core.Matter#Raw() x
			join	@addedSpec      c on c.MatterID=x.ID			
		)
		update	cteParcel set PID=@sackID;
		END

		update shpt._Sack set SackWt=@sackWt;

		COMMIT	TRAN;
		END TRY
		BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
		END CATCH	
END