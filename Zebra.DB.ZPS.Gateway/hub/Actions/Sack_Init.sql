/*
@slip    tvp =Comma[ParcelID]
@spec	 tvp =Triad<RouteID, POA, SackWt>
@result	 tvp=Duad<SackID, MIC>
*/
--Smile
CREATE PROCEDURE [hub].[Sack$Init](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	
		declare	@userID I32,    @hubID I32,	  @roleID I32;
		select	@userID=UserID, @hubID=HubID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@routeID I32, @brokerID I32, @clrMethodID I32, 
				@poa char(3), @weight float;
		select	@routeID=v1,  @brokerID=BrokerID,  @clrMethodID=ClrMethodID, 
				@poa=v2, @weight=v3
		from	tvp.Triad#Of(@context, default) x
		join	tms.Route#Raw() t on t.ID=cast(x.v1 as int);

		declare	@spec core.TransitionSpec,
				@actionID	E32=(select AddParcelToSack from core.Action#ID());
		insert	@spec select t.* 
		from	shpt.Parcel#Raw() x
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t
		where	x.ID  in (select ID from tvp.I64#Slice(@slip))
		and		x.RouteID=@routeID
		and		x.RcvHubID=@hubID;

		if(exists (select * from @spec))
		begin
		SET XACT_ABORT ON;
		BEGIN TRY
		BEGIN	TRAN;
		declare	@type	    E32=(select Sack from core.Matter#Type()),
				@stateID    I32=(select SackCreated from core.State#ID()),
				@stage		I32=(select Sacked from core.Stage#ID()),
				@source     E8=(select InfoPath		from core.Source#ID()),
				@sackID		I64=(next value for core.MatterSeq);
	
		
		insert	core._Matter
				(     ID, PID, PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		values	(@sackID, 0,     @hubID, @stateID, @stage, @source, @type, getutcdate());

		insert	shpt._Sack
				(    ID,   BrokerID,  ClrMethodID,  POA,  SackWt)
		values	(@sackID, @brokerID, @clrMethodID, @poa, @weight)
		
		insert	core._Activity
				(MatterID,  StateID,  UserID,  TalliedOn)
		values	( @sackID, @stateID, @userID,  getutcdate());

		declare	@sackNbrType E8=(select MIT from core.RefNbr#Type()),
				@sackNbr loc.RefNbr=(select MIC from core.MIC#Emit(@sackID, @source, @type, getutcdate()));

		insert	core._RefNbr( MatterID,       Type,  Number)
		values              (@sackID, @sackNbrType, @sackNbr);

		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		with cteParcel as
		(
			select	ID, PID
			from	core.Matter#Raw() x
			join	@spec c on c.MatterID=x.ID			
		)
		update	cteParcel set PID=@sackID;

		select	@result=(select Tvp from tvp.Duad#Make(@sackID, @sackNbr));

			COMMIT	TRAN;
		END TRY
		BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
		END CATCH
		end	
END