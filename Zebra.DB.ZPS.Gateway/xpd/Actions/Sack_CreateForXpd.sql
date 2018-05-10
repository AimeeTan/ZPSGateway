/*
	@slip    = Many[Triad<SackNbr, Weight, string.Join(at.Spr.Comma, Mics)>]
	@context = Duad<SackMftID, ClrMethodID>
	@result  = Many[Duad<SackID, SackNbr>]
*/
-- Daxia
CREATE PROCEDURE [xpd].[Sack$CreateForXpd](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;
		
		-- 1.0	Check Parcel Transit
		declare	@userID I32,    @siteID I32,    @roleID I32;
		select	@userID=UserID, @siteID=SiteID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare @actionID E32=(select ImportOutgateManifest from core.Action#ID())

		declare	@sackMftID I64, @clrMethodID I32;
		select	@sackMftID=v1,  @clrMethodID=v2
		from	tvp.Duad#Of(@context, default);

		-- 1.1	Init Sack
		declare	@now      DT=getutcdate()
		,		@type     E8 =(select Sack			from core.Matter#Type())
		,		@stage    E32=(select SackManifested from core.Stage#ID())
		,		@stateID  I32=(select SackManifested from core.State#ID())
		;
		declare	@source E8,     @brokerID I32,      @poa char(3);
		select	@source=Source, @brokerID=BrokerID, @poa=POA
		from	shpt.SackMft#Base() where ID=@sackMftID

		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.MatterSeq, Nbr
		from	dbo.Nbr#Emit(tvp.Many@Count(@slip));

		insert	core._Matter
		(		ID,          PID, PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		select	x.ID, @sackMftID,  @siteID, @stateID, @stage, @source, @type,     @now
		from	@idSeqs x;

		insert	shpt._Sack
		(		  ID,  BrokerID,  ClrMethodID,  POA, SackWt)
		select	x.ID, @brokerID, @clrMethodID, @poa, s.v2
		from	@idSeqs x
		join	tvp.Triad#Slice(@slip, default, default) s on s.Seq=x.Seq;

		insert	core._Activity
		(		MatterID,  StateID,  UserID, TalliedOn)
		select	      ID, @stateID, @userID,      @now
		from	@idSeqs;
		
		-- 1.2	Insert Mic
		insert	core._RefNbr
		(		MatterID, Type,  Number)
		select	    x.ID, k.MIT, m.MIC
		from	@idSeqs x cross apply core.RefNbr#Type() k
		cross	apply core.MIC#Emit(x.ID, @source, @type, @now) m;
		-- 1.3	Insert RefNbr
		declare	@idTexts I64Texts;
		insert	core._RefNbr
		(		MatterID, Type,  Number)
		output	inserted.MatterID, inserted.Number into @idTexts
		select	    x.ID, k.ClientRef, s.v1
		from	@idSeqs x cross apply core.RefNbr#Type() k
		join	tvp.Triad#Slice(@slip, default, default) s on s.Seq=x.Seq
		;

		-- 2.1	Link Parcel's PID from SackMft to Sack:
		with cteParcel as
		(
			select	m.ID, m.PID, SackID=x.ID 
			from	@idSeqs x
			join	tvp.Triad#Slice(@slip, default, default) s on s.Seq=x.Seq
			cross	apply tvp.Comma#Slice(s.v3)                          i
			cross	apply core.RefNbr#ScanOne(i.Piece, default, default) r
			join	core.Matter#Raw() m on m.ID=r.MatterID and m.PID=0
		)
		update cteParcel set PID=SackID;


		-- 2.2	Transit Parcel
		declare	@ids I64Array; insert @ids(ID) select m.MatterID
		from	tvp.Triad#Slice(@slip, default, default)             x
		cross	apply tvp.Comma#Slice(x.v3)                          i
		cross	apply core.RefNbr#ScanOne(i.Piece, default, default) m
		;
		declare	@idCommas tvp=(select Tvp from tvp.I64#Join(@ids));

		declare	@spec core.TransitionSpec; insert @spec select t.* 
		from	shpt.Parcel#TobeVia(@idCommas, @roleID, @actionID) t;

		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=0;

		-- 3.1	Return Result
		with cteResult(text) as
		(
			select	[text()]=concat(k.Many, x.ID, k.Duad, x.Text)
			from	tvp.Spr#Const() k, @idTexts x
			for		xml path(N'')
		)
		select	@result=x.Tvp from cteResult 
		cross	apply tvp.Spr#Purify(text, default)  x
		;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END