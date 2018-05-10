/*
@slip=    Comma[StockInOrderID]
@context= RcvHubID
@result=  Comma[StockInOrderID]
*/
--Smile
CREATE PROCEDURE [vmi].[StockInOrder$Import](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@actionID I32=(select ImportAsn from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec 		
		select	t.* 
		from	tvp.I64#Slice(@slip) x
		cross	apply core.Matter#Tobe(x.ID, @roleID, @actionID) t;
        
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		--with cteAsn as
		--(
		--	select	ID, TotalSkuQty, NewTotalSkuQty=cast(v2 as int)
		--	from	tvp.Duad#Slice(@slip, default, default) x
		--	join	@spec                                   c on c.MatterID=cast(v1 as bigint)
		--	join	whse.StockInOrder#Raw()                 s on s.ID=c.MatterID

		--)
		--update cteAsn set TotalSkuQty=NewTotalSkuQty;

		with cte(text) as
		(
			select	[text()]=concat(N',', MatterID)
			from	@spec
			for xml path(N'')
		)
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END