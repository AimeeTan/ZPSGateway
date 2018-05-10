/*
@slip    =Trio<NormalParcel, CPSParcel, MPSParcel>
@context = Duad<errorCnt, errors>
@result  =Pair<BatchID, Quad[ClientRef, MIC, Precourier, SvcType)
*/
--Smile
CREATE PROCEDURE [api].[Parcel$UnfiledInitByPlatform](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@siteID I32=(select SiteID from	loc.Tenancy#Of(@tenancy));
		declare	@errorCnt int, @errors json;
		select	@errorCnt=v1,  @errors=v2
		from	tvp.Duad#Of(@context, default) x;

		declare	@batchID I64;
		execute	shpt.Batch#Create @id=@batchID out, @siteID=@siteID, @errorCnt=@errorCnt, @errors=@errors;

		declare	@normal tvp, @cps tvp, @mps tvp;
		select	@normal=v1, @cps=v2, @mps=v3
		from	tvp.Trio#Of(@slip);
		if(@cps>N'')
			execute	shpt.Parcel#UnfiledCPSInitByPlatform    @slip=@cps, @context=@batchID, @tenancy=@tenancy;
		if(@mps>N'')
			execute	shpt.Parcel#UnfiledMPSInitByPlatform    @slip=@mps, @context=@batchID, @tenancy=@tenancy;
		if(@normal>N'')
			execute	shpt.Parcel#UnfiledNormalInitByPlatform @slip=@normal, @context=@batchID, @tenancy=@tenancy;
	
		-- 5.	Result:
		with cteResult(text) as
		(

			select	[text()]=concat(s.Many, r.Number, s.Quad, m.Number, s.Quad, p.Number, s.Quad, x.SvcType)
			from	shpt.Parcel#Base()       x
			cross	apply core.RefNbr#Type() k
			left	join  core.RefNbr#Raw()  r on r.MatterID=x.ID and r.Type=k.ClientRef
			left	join  core.RefNbr#Raw()  p on p.MatterID=x.ID and p.Type=k.PreCourier
			join	core.RefNbr#Raw()        m on m.MatterID=x.ID and m.Type=k.MIT
			cross	apply tvp.Spr#Const()    s
			where	x.BatchID=@batchID
			for		xml path(N'')
		)
		select	@result=r.Tvp 
		from	cteResult 
		cross	apply tvp.Spr#Purify(text, default)  x
		cross	apply tvp.Pair#Make(@batchID, x.Tvp) r
		;
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
