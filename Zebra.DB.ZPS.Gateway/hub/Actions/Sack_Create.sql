/*
	@slip    = Comma<ParceID>
	@context = Triad<ManifestID, ClrMethodID, Weight>
	@result  = Triad<SackID, SackNbr, Comma<ErrorParcelIDs>>
*/
-- AaronLiu
CREATE PROCEDURE [hub].[Sack$Create](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	-- 1.0	Check Parcel Transit
	declare	@userID I32,    @hubID I32,	  @roleID I32;
	select	@userID=UserID, @hubID=HubID, @roleID=RoleID
	from	loc.Tenancy#Of(@tenancy);

	declare @invalidIDs tvp
	,		@actionID	E32=(select AddParcelToSack from core.Action#ID())
	,		@ids		I64Array
	,		@spec		core.TransitionSpec;
	insert	@spec 
	output	inserted.MatterID into @ids
	select	t.* 
	from	shpt.Parcel#TobeVia(@slip, @roleID, @actionID) t;

	with cte(text) as
	(
		select	[text()]=concat(N',', x.ID)
		from	tvp.I64#Slice(@slip) x
		left	join @ids			 p on x.ID=p.ID
		where	p.ID is null for xml path (N'')
	)
	select	@invalidIDs=Tvp from cte cross apply tvp.Spr#Purify(text, 1);
	if		@invalidIDs<>N''
	begin
		select	@result=Tvp from tvp.Triad#Make(N'0', N'', @invalidIDs);
		return;
	end	

	BEGIN TRY
		BEGIN	TRAN;

		declare	@manifestID I64, @clrMethodID I32, @weight float;
		select	@manifestID=v1,  @clrMethodID=v2,  @weight=v3
		from	tvp.Triad#Of(@context, default);

		-- 1.1	Init Sack
		declare	@now      DT=getutcdate()
		,		@type     E8=(select Sack			from core.Matter#Type())
		,		@stage    E32=(select SackManifested from core.Stage#ID())
		,		@source   E8=(select InfoPath		from core.Source#ID())
		,		@stateID I32=(select SackManifested from core.State#ID())
		,		@sackID	 I64=next value for core.MatterSeq
		;

		insert	core._Matter
				(     ID,         PID, PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		values	(@sackID, @manifestID,   @hubID, @stateID, @stage, @source, @type,     @now);

		insert	shpt._Sack
				(    ID, BrokerID,  ClrMethodID, POA,  SackWt)
		select	@sackID, BrokerID, @clrMethodID, POA, @weight
		from	shpt.SackMft#Raw()
		where	ID=@manifestID

		insert	core._Activity
				(MatterID,  StateID,  UserID, TalliedOn)
		values	( @sackID, @stateID, @userID,      @now);

		declare	@idTexts I64Texts;
		insert	core._RefNbr
		(		MatterID, Type,  Number)
		output	inserted.MatterID, inserted.Number into @idTexts
		select	@sackID,  k.MIT, m.MIC
		from	core.RefNbr#Type() k
		cross	apply core.MIC#Emit(@sackID, @source, @type, @now) m
		;

		-- 2.1	Link Parcel's PID from SackMft to Sack:
		with cteParcel as
		(
			select	m.ID, m.PID
			from	tvp.I64#Slice(@slip) x
			join	core.Matter#Raw() m on x.ID=m.ID
		)
		update cteParcel set PID=@sackID;

		-- 2.2	Transit Parcel
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		-- 3.1	Return Result
		select	@result=r.Tvp
		from	@idTexts x
		cross	apply tvp.Triad#Make(x.ID, x.Text, N'') r;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END