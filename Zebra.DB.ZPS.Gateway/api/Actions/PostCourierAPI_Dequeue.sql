-- Aimee
CREATE PROCEDURE [api].[PostCourierAPI$Dequeue](@result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@source E8=(select InfoPath			 from core.Source#ID())
		,		@qtype	E8=(select MftPostCourierAPI from core.Queue#Type());
		execute	core.OutboundQ#Dequeue @source=@source, @qtype=@qtype, @result=@result out;

		--	1.	find LastMilerID and ParcelID
		declare	@pairs I64Pairs;
		insert	@pairs
		select	x.LastMilerID, x.ID
		from	tvp.Spr#Const() k, tvp.Quad#Slice(@result, default, default) q
		cross	apply core.Matter#PNodeDn(cast(q.v1 as bigint))              m
		join	shpt.Parcel#Raw() x on x.ID=m.ID
		cross	apply core.Matter#Type() t 
		where	m.Type=t.Parcel;

		--	2.Group by LastMilerID 
		with cteGroup as
		(
			select	LastMilerID=x.LID from @pairs x group by x.LID
		)
		,cteResult(text) as
		(
			select	[text()]=concat(k.Entry, c.LastMilerID, k.Duad, stuff(z.Parcels, 1, 3, N'')) 
			from	tvp.Spr#Const() k, cteGroup c
			cross	apply
			(
				select	[text()]=concat(k.Many, x.RID)
				from	tvp.Spr#Const() k, @pairs x
				where	x.LID=c.LastMilerID
				for xml path(N'')
			) z(Parcels)
			for xml path(N'')
		)
		select @result=Tvp from cteResult cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
