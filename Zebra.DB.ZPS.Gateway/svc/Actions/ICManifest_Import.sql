/*
@slip = Many[Duad<MIC, TrkNbr>]
*/
--PeterHo, Eva:For Special POA(TPE,HKG), no need postcourierNbr still can transit
CREATE PROCEDURE [svc].[ICManifest$Import](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);
	
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

		declare	@actionID I32=(select ICManifest from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @ids
		cross	apply shpt.Parcel#Maybe(ID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END