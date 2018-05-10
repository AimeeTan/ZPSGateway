/*
@slip   =Many[Duad<OrderNbr, FirstMilerNbr>]
*/
--Aimee, AaronLiu
CREATE PROCEDURE [svc].[Parcel$MergePreCourier](@slip tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		--1.Merge RefNbr
		declare	@maxStage E32=( select RouteCfmed from core.Stage#ID())
		,		@type     E8=( select PreCourier from core.RefNbr#Type())
		,		@siteID   I32=(select SiteID     from loc.Tenancy#Of(@tenancy))
		,		@clientRefType E8=( select ClientRef from core.RefNbr#Type());
		
		declare	@idSeqs I64Seqs;
		with ctePreNbr as
		(
			select	MatterID=m.ID, Number=cast(x.v2 as varchar(40)), x.Seq
			from	tvp.Duad#Slice(@slip, default, default) x
			cross	apply loc.RefNbr#Cast(x.v1)             r
			join	core.RefNbr#Raw() n on n.Number=r.Number and n.Type=@clientRefType
			join	core.Matter#Raw() m on m.ID=n.MatterID   and m.Stage<@maxStage and m.PosterID=@siteID
		)
		merge	core._RefNbr as r using ctePreNbr as n
		on		(r.MatterID=n.MatterID and r.Type=@type)
		when	matched     and n.Number=N'' then delete
		when	matched     and n.Number>N'' then update set r.Number=n.Number
		when	not matched and n.Number>N'' then insert(MatterID,  Type,   Number)
												values(n.MatterID, @type, n.Number)
		output	inserted.MatterID, n.Seq into @idSeqs;

		--2.find Orphan  TODO: 
		declare	@firstMilerNbrs tvp;
		with	cte(text) as
		(
			select	[text()]=concat(N',', v2)
			from	tvp.Duad#Slice(@slip, default, default)
			for		xml path(N'')
		)
		select	@firstMilerNbrs=Tvp from cte cross apply tvp.Spr#Purify(text, 1);
		execute	shpt.Orphan#Adopt @slip=@firstMilerNbrs, @tenancy=@tenancy;

		--3.return result
		with cteResult (text) as
		(
			select	[text()]=concat(k.Many, x.v1)
			from	tvp.Duad#Slice(@slip, default, default) x
			left	join @idSeqs i on i.Seq=x.Seq
			cross	apply tvp.Spr#Const()   k
			where	i.ID is null
			for		xml path(N'')
		)
		select	@result=Tvp from cteResult cross apply tvp.Spr#Purify(text, default);
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
