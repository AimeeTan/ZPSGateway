/*
	@slip    = Block[Comma<AddedParceID>, Comma<RemovedParceID>]
	@context = Duad<SackID, Weight>
*/
-- AaronLiu
CREATE PROCEDURE [hub].[Sack$Close](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	declare	@userID I32,    @roleID I32;
	select	@userID=UserID, @roleID=RoleID
	from	loc.Tenancy#Of(@tenancy);
	declare @invalidIDs		tvp
	,		@addActionID	E32=(select AddParcelToSack		 from core.Action#ID())
	,		@removeActionID E32=(select RemoveParcelFromSack from core.Action#ID())
	,		@ids			I64Enums
	,		@spec			core.TransitionSpec;
	insert	@spec 
	output	inserted.MatterID, 1 into @ids
	select	t.* 
	from	tvp.Block#At(1, @slip, default, default) x
	cross	apply shpt.Parcel#TobeVia(x.Tvp, @roleID, @addActionID) t;

	insert	@spec 
	output	inserted.MatterID, 0 into @ids
	select	t.* 
	from	tvp.Block#At(2, @slip, default, default) x
	cross	apply shpt.Parcel#TobeVia(x.Tvp, @roleID, @removeActionID) t;

	with cteParcel as
	(
		select	p.ID
		from	tvp.Spr#Const() k
		cross	apply tvp.I64#Slice(replace(@slip, k.Block, N',')) p 
		where	p.ID>0
	), cte(text) as
	(
		select	[text()]=concat(N',', x.ID)
		from	cteParcel x
		left	join  @ids p on x.ID=p.ID
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

		-- 1.1	Update Sack Weight
		declare	@sackID I64, @weight float;
		select	@sackID=v1,  @weight=v2
		from	tvp.Duad#Of( @context, default);
		update	shpt._Sack set SackWt=@weight where ID=@sackID;

		-- 2.1	Merge Parcels into Sack:
		declare	@sackMftID I64=(select PID from core.Matter#Raw() where ID=@sackID)
		;
		with cteDiff as
		(
			select	m.ID, m.PID, NewPID=iif(x.Val=1, @sackID, @sackMftID)
			from	@ids x
			join	core.Matter#Raw() m on x.ID=m.ID
		)
		update cteDiff set PID=NewPID;

		-- 2.2	Transit Parcel:
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END