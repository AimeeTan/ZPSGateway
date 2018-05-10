/*
	@slip    = Many[Duad<MIC, TrkNbr>];
	@context = Quad<HubID, POA, BrokerID, Mawb>
*/
-- AaronLiu, Eva:For Special POA(TPE,HKG), no need postcourierNbr still can transit
CREATE PROCEDURE [svc].[SackMft$Import](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;

		-- 1.1	Init SackMft
		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@hubID I32, @pOA char(3), @brokerID I32, @mawbNbr char(11)
		select	@hubID=v1,  @pOA=v2,      @brokerID=v3,  @mawbNbr=v4
		from	tvp.Quad#Of(@context, default)

		declare	@now        DT=getutcdate();
		declare	@type       E8=(select SackMft        from core.Matter#Type());
		declare	@stage      E32=(select SackManifested from core.Stage#ID());
		declare	@source     E8=(select InfoPath       from core.Source#ID());
		declare	@stateID   I32=(select SackMftCreated from core.State#ID());
		declare	@sackMftID I64=next value for core.MatterSeq;

		insert	core._Matter
				(ID,         PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		values	(@sackMftID,   @hubID, @stateID, @stage, @source, @type,     @now);

		insert	shpt._SackMft
				(       ID,  POA, POD,  BrokerID,  MawbNbr, FlightNbr)
		select	@sackMftID, @pOA, N'', @brokerID, @mawbNbr,       N''
		from	tvp.Triad#Of(@context, default)

		insert	core._Activity
				(  MatterID,  StateID,  UserID, TalliedOn)
		values	(@sackMftID, @stateID, @userID,      @now);

		-- 2.1	Merge PostCourier
		declare	@ids I64Array;
		/*BEGIN--For Special POA(TPE,HKG), no need postcourierNbr still can transit*/
		declare	@refNbrSlip tvp;
		with	cte(text) as
		(
			select	[text()]=concat(k.Many, i.MatterID, k.Triad, t.PostCourier, k.Triad, x.v2)
			from	tvp.Duad#Slice(@slip, default, default) x
			cross	apply loc.RefNbr#Cast(x.v1)   m
			cross	apply core.MIC#IdOf(m.Number) i
			cross	apply core.RefNbr#Type() t
			cross	apply tvp.Spr#Const()    k
			for		xml path(N'')
		)
		select	@refNbrSlip=Tvp from cte cross apply tvp.Spr#Purify(text, default);
		exec	core.RefNbr#Merge @slip=@refNbrSlip;

		with	cte as
		(
			select	MatterID=cast(x.v1 as bigint)
			from	tvp.Triad#Slice(@refNbrSlip, default, default) x
		)
		insert	@ids select MatterID from cte
		/*END--For Special POA(TPE,HKG), no need postcourierNbr still can transit*/
		--with cteSlip as
		--(
		--	select	i.MatterID, Type=k.PostCourier, n.Number
		--	from	tvp.Duad#Slice(@slip, default, default) x
		--	cross	apply loc.RefNbr#Cast(x.v1)   m
		--	cross	apply loc.RefNbr#Cast(x.v2)   n
		--	cross	apply core.MIC#IdOf(m.Number) i
		--	cross	apply core.RefNbr#Type()      k
		--)
		--merge	into core._RefNbr as o using cteSlip as n
		--on		(o.MatterID=n.MatterID and o.Type=n.Type)
		--when	    matched and n.Number>N'' then update set o.Number=n.Number
		--when	not matched	and n.Number>N'' then insert (  MatterID,   Type,   Number)
		--										  values (n.MatterID, n.Type, n.Number)
		--output	inserted.MatterID into @ids;

		-- 2.2	Transit Parcel To ICManifested
		declare	@actionID I32=(select ICManifest from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @ids
		cross	apply shpt.Parcel#Maybe(ID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpecWithPID @spec=@spec, @userID=@userID, @pid=@sackMftID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END