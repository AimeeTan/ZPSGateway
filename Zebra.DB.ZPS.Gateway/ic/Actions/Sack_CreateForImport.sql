/*
	@slip    = Entry[Triad<PickupNbr, PickupedOn, Many[Duad<ParcelID, Weight>]>]
	@context = ManifestID
*/
-- Daxia
CREATE PROCEDURE [ic].[Sack#CreateForImport](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;
		
		-- 0.	Tenancy & Contexts:
		declare	@userID I32,    @hubID I32,	  @roleID I32;
		select	@userID=UserID, @hubID=HubID, @roleID=RoleID    --HubID is IC Site
		from	loc.Tenancy#Of(@tenancy);
		
		declare	@sackMftID I64=@context, @clrMethodID I32=0, @weight float=0;

		-- 1	Init Matters & Sacks
		declare	@now      DT=getutcdate()
		,		@type     E8=(select Sack			 from core.Matter#Type())
		,		@stage    E32=(select SackManifested from core.Stage#ID())
		,		@source   E8=(select InfoPath		 from core.Source#ID())
		,		@stateID I32=(select SackManifested  from core.State#ID())
		,		@sackID	 I64=next value for core.MatterSeq
		;
		
		-- 1.1	Init Matters
		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		insert	core._Matter
				( ID,        PID, PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		select	x.ID, @sackMftID,   @hubID, @stateID, @stage, @source, @type,     @now
		from	@idSeqs x;
		
		
		-- 1.2	Init Sacks
		declare	@poa char(3), @brokerID I32;
		select	@poa=POA,     @brokerID=BrokerID from shpt.SackMft#Raw() where ID=@sackMftID;

		insert	shpt._Sack
				( ID,  BrokerID,  ClrMethodID,  POA,  SackWt)
		select	  ID, @brokerID, @clrMethodID, @poa, @weight
		from	@idSeqs ;
		

		-- 1.3	Add Activities : 
		insert	core._Activity
				(MatterID,  StateID,  UserID, TalliedOn)
		select	       ID, @stateID, @userID, @now from @idSeqs ;
		
		-- 1.4	Add RefNbrs - Mic : 
		insert	core._RefNbr (MatterID, Type, Number) select x.ID, k.MIT, m.MIC
		from	@idSeqs x cross apply core.RefNbr#Type() k cross apply core.MIC#Emit(x.ID, @source, @type, @now) m
		;
		
		-- 1.5	Add RefNbrs - ClientRef : 
		insert	core._RefNbr (MatterID, Type, Number) select x.ID, k.ClientRef, s.v1
		from	@idSeqs x cross apply core.RefNbr#Type() k
		join	tvp.Triad#Slice(@slip, default, N'	;	') s on s.Seq=x.Seq
		;

		-- 2.1	Link Parcel's PID from SackMft to Sack:
		declare	@ids I64Array;
		with cteMatter as
		(
			select	m.ID, m.PID, SackID=x.ID
			from	@idSeqs x
			join	tvp.Triad#Slice(@slip, default, N'	;	') s on s.Seq=x.Seq
			cross	apply tvp.Duad#Slice(s.v3, default, default) p
			join	core.Matter#Raw() m on x.ID=p.v1
		)
		update cteMatter set PID=SackID
		output	inserted.ID into @ids
		;
		with cteParcel as
		(
			select	ID=p.v1, MeasureWt=cast(p.v2 as real)
			from	@idSeqs x
			join	tvp.Triad#Slice(@slip, default, N'	;	') s on s.Seq=x.Seq
			cross	apply tvp.Duad#Slice(s.v3, default, default) p
		)
		--update	cteParcel set Weight=NewWeight;
		update	o set o.Weight=n.MeasureWt
		from	shpt._Parcel o join cteParcel n on o.ID=n.ID;

		---- 2.2	Transit Parcel
		declare	@parcelActionID E32=(select ImportOutgateManifest from core.Action#ID())
		,		@spec           core.TransitionSpec;
		with cte(text) as
		(
			select	[text()]=concat(N',', x.ID) from @ids x
			where	x.ID is null for xml path (N'')
		)
		insert	@spec select t.* from cte     x
		cross	apply tvp.Spr#Purify(text, 1) i
		cross	apply shpt.Parcel#TobeVia(i.Tvp, @roleID, @parcelActionID) t;

		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;


		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END