/*
	@slip = Comma<PreCourierNbr>
*/
-- AaronLiu
CREATE PROCEDURE [shpt].[PreCourier#Concern](@slip tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@minStage E32,    @maxStage E32;
		select	@minStage=PreMin, @maxStage=CurMax
		from	core.Stage#Boundary();

		declare	@concernType E8=(select PreCouierDuplicate from core.Concern#Type())
		;
		with	cte as
		(
			select	Seq, Number=Piece
			from	tvp.Comma#Slice(@slip)
			where	Piece>N''
		),	cteMatched as
		(
			select	distinct n.MatterID
			,		MatchedCnt=count(1) over(partition by Seq)
			from	core.RefNbr#Type() t, core.Matter#Type() e, cte x
			join	core.RefNbr#Raw()  n on x.Number=n.Number 
			join	core.Matter#Raw()  m on n.MatterID=m.ID
			where	n.Type=t.PreCourier and m.Type<>e.OrphanParcel 
			and		m.Stage between @minStage and @maxStage
		), cteSlip(text) as
		(
			select	[text()]=concat(k.Many, x.MatterID, k.Duad, @concernType)
			from	cteMatched x, tvp.Spr#Const() k
			where	MatchedCnt>1
			for		xml path(N'')
		)
		select	@slip=Tvp from cteSlip cross apply tvp.Spr#Purify(text, default);
		execute	core.Concern#AddVia @slip=@slip;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END