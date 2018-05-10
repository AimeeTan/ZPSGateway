/*
@slip   = at.Tvp.Quad.Join(ClientRefNbr, IDNbr, IDName, Phone).Over(at.Tvp.Many)
@result = at.Tvp.Many.Join(NotFoundClientRefNbr)
*/
--Eva, Smile, PeterHo
CREATE PROCEDURE [svc].[IDNbr$Import](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@siteID     I32=(select SiteID     from loc.Tenancy#Of(@tenancy))
		,		@maxStage    E32=(select RouteCfmed from core.Stage#ID())
		,		@refNbrType  E8=(select	ClientRef  from core.RefNbr#Type())
		,		@idInfoType  E8=(select IDInfo     from core.RefInfo#Type());
		
		declare	@idSeqs I64Seqs;
		with cteNew as
		(
			select	MatterID=m.ID
			,		Info=concat(x.v2/*IDNbr*/,        d.Tuplet,
					'0'/*IsValid*/,                   d.Tuplet, 
					x.v3/*Name*/,                     d.Tuplet,
					x.v4/*Phone*/,                    d.Tuplet,
					''/*PreviousName*/)
			,		x.Seq
			from	tvp.Quad#Slice(@slip, default, default) x cross apply loc.RefNbr#Cast(x.v1) r
			join	core.RefNbr#Raw() n on n.Number=r.Number and n.Type=@refNbrType
			join	core.Matter#Raw() m on m.ID=n.MatterID   and m.Stage<@maxStage and m.PosterID=@siteID
			cross	apply tvp.Spr#Const() d
		)
		merge	core._RefInfo as o using cteNew as n
		on		(o.MatterID=n.MatterID and o.Type=@idInfoType)
		when	matched     and n.Info=N'' then delete
		when	matched     and n.Info>N'' then update set Info=n.Info
		when	not matched and n.Info>N'' then insert(  MatterID,  Type,         Info)
												values(n.MatterID, @idInfoType, n.Info)
		output	inserted.MatterID, n.Seq into @idSeqs;

		with cteResult (text) as
		(
			select	[text()]=concat(k.Many, x.v1)
			from	tvp.Quad#Slice(@slip, default, default) x
			left	join @idSeqs i on i.Seq=x.Seq
			cross	apply tvp.Spr#Const() k
			where	i.ID is null
			for xml path(N'')
		)
		select	@result=Tvp from cteResult cross apply tvp.Spr#Purify(text, default);

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
