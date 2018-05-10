/*
	@slip    = Comma<SackID>
	@context = Duad<TruckerID, BookingNbr>
	@result  = Traid[SackLoadID, SackLoadMIC, Comma<InvalidSackID>]
*/
-- AaronLiu
CREATE PROCEDURE [hub].[Sack$Load](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	-- 1.0	Check Sack Transit
	declare	@userID I32,    @hubID I32,	  @roleID I32;
	select	@userID=UserID, @hubID=HubID, @roleID=RoleID
	from	loc.Tenancy#Of(@tenancy);

	declare @invalidIDs tvp
	,		@actionID	E32=(select AddToSackLoad from core.Action#ID())
	,		@ids		I64Array
	,		@spec		core.TransitionSpec;
	insert	@spec 
	output	inserted.MatterID into @ids
	select	t.* 
	from	core.Matter#TobeVia(@slip, @roleID, @actionID) t;

	with cte(text) as
	(
		select	[text()]=concat(N',', x.ID)
		from	tvp.I64#Slice(@slip)  x
		left	join @ids			  p on x.ID=p.ID
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

		-- 1.1	Init SackLoad
		declare	@truckerID I32, @number loc.RefNbr;
		select	@truckerID=v1,	@number=v2
		from	tvp.Duad#Of(@context, default);

		declare	@now         DT=getutcdate()
		,		@type        E8=(select SackLoad        from core.Matter#Type())
		,		@stage       E32=(select SackLoaded      from core.Stage#ID())
		,		@source      E8=(select InfoPath        from core.Source#ID())
		,		@stateID    I32=(select SackLoadCreated	from core.State#ID())
		,		@sackLoadID	I64=next value for core.MatterSeq
		;

		insert	core._Matter
				(ID,		  PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		values	(@sackLoadID,   @hubID, @stateID, @stage, @source, @type,     @now);

		insert	shpt._SackLoad
				(ID,		   TruckerID)
		values	(@sackLoadID, @truckerID)

		insert	core._Activity
				(MatterID,     StateID,  UserID, TalliedOn)
		values	(@sackLoadID, @stateID, @userID,      @now);

		declare	@refNbrs tvp;
		with cteRefNbr as
		(
			select	MatterID=@sackLoadID, Type=k.MIT,		 Number=m.MIC
			from	core.RefNbr#Type() k
			cross	apply core.MIC#Emit(@sackLoadID, @source, @type, @now) m
			union	all
			select	MatterID=@sackLoadID, Type=k.BookingNbr, Number=@number
			from	core.RefNbr#Type() k
		), cte(text) as
		(
			select	[text()]=concat(k.Many, MatterID, k.Triad, Type, k.Triad, Number)
			from	tvp.Spr#Const() k, cteRefNbr for xml path(N'')
		)
		select	@refNbrs=Tvp from cte cross apply tvp.Spr#Purify(text, default);
		execute	core.RefNbr#Merge @slip=@refNbrs;

		-- 2.1	Link Sack's AID To SackLoad
		with cteSack as
		(
			select	m.ID, m.AID
			from	tvp.I64#Slice(@slip) x
			join	core.Matter#Raw() m on x.ID=m.ID	
		)
		update	cteSack set AID=@sackLoadID;

		-- 2.2	Transit Sack
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		-- 3.1	Return Result
		select	@result=r.Tvp
		from	tvp.Triad#Slice(@refNbrs, default, default) x
		cross	apply tvp.Triad#Make(x.v1, x.v3, N'')		r
		cross	apply core.RefNbr#Type()					k
		where	k.MIT=cast(x.v2 as tinyint)
		;
		
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
