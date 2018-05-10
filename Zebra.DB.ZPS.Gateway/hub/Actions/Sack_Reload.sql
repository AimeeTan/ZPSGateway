/*
	@slip    = Block[Comma<AddedSackID>, Comma<RemovedSackID>]
	@context = Traid<SackLoadID, TruckerID, BookingNbr>
	@result  = Comma<InvalidSackID>
*/
-- AaronLiu
CREATE PROCEDURE [hub].[Sack$Reload](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	-- 1.0	Check Sack Transit
	declare	@userID I32,    @roleID I32;
	select	@userID=UserID, @roleID=RoleID
	from	loc.Tenancy#Of(@tenancy);
	declare @invalidIDs		tvp
	,		@addActionID	E32=(select AddToSackLoad	   from core.Action#ID())
	,		@removeActionID E32=(select RemoveFromSackLoad from core.Action#ID())
	,		@ids			I64Enums
	,		@spec			core.TransitionSpec;
	insert	@spec 
	output	inserted.MatterID, 1 into @ids
	select	t.* 
	from	tvp.Block#At(1, @slip, default, default) x
	cross	apply core.Matter#TobeVia(x.Tvp, @roleID, @addActionID) t;

	insert	@spec 
	output	inserted.MatterID, 0 into @ids
	select	t.* 
	from	tvp.Block#At(2, @slip, default, default) x
	cross	apply core.Matter#TobeVia(x.Tvp, @roleID, @removeActionID) t;

	with cteSack as
	(
		select	s.ID
		from	tvp.Spr#Const() k
		cross	apply tvp.I64#Slice(replace(@slip, k.Block, N',')) s
		where	s.ID>0
	), cte(text) as
	(
		select	[text()]=concat(N',', x.ID)
		from	cteSack   x
		left	join @ids p on x.ID=p.ID
		where	p.ID is null for xml path (N'')
	)
	select	@invalidIDs=Tvp from cte cross apply tvp.Spr#Purify(text, 1);
	if		@invalidIDs<>N''
	begin
		select	@result=@invalidIDs;
		return;
	end	

	BEGIN TRY
		BEGIN	TRAN;
			
		-- 1.1	Update SackLoad Info
		declare	@sackLoadID I64, @truckerID I32, @number loc.RefNbr;
		select	@sackLoadID=v1,	 @truckerID=v2,	 @number=v3
		from	tvp.Triad#Of(@context, default);

		update	shpt._SackLoad set TruckerID=@truckerID where ID=@sackLoadID;
		
		declare	@refNbrs tvp;
		select	@refNbrs=n.Tvp
		from	core.RefNbr#Type() t
		cross	apply tvp.Triad#Make(@sackLoadID, t.BookingNbr, @number) n;
		execute	core.RefNbr#Merge @slip=@refNbrs;

		-- 2.1	Merge Sacks Into SackLoad
		with cteDiff as
		(
			select	m.ID, m.AID, NewAID=iif(x.Val=1, @sackLoadID, 0)
			from	@ids x
			join	core.Matter#Raw() m on x.ID=m.ID
		)
		update	cteDiff set AID=NewAID;

		-- 2.2	Transit Sack:
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END