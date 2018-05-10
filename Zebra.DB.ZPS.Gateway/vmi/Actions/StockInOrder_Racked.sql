/*
@slip=    Many[Duad<AsnNbr, TotalSkuQty>]
@result=  RackedCnt
*/
--Smile
CREATE PROCEDURE [vmi].[StockInOrder$Racked](@slip tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@daemon I32=0;		
		declare	@actionID I32=(select CfmAsnRacked from core.Action#ID());

		declare	@orderIDs I64Array;
		insert	@orderIDs select  MatterID
		from	tvp.Duad#Slice(@slip, default, default)  x
		cross	apply core.RefNbr#Type() k
		join	core.RefNbr#Raw()        r on  x.v1=r.Number and r.Type=k.AsnNbr;

		declare	@spec core.TransitionSpec;
		insert	@spec 		
		select	t.* 
		from	@orderIDs r
		cross	apply core.Matter#Tobe(r.ID, @daemon, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@daemon, @beAffected=1;

		with cte as
		(
			select	TotalSkuQty, NewTotalSkuQty=cast(x.v2 as int)
			from	tvp.Duad#Slice(@slip, default, default)  x
			cross	apply core.RefNbr#Type() k
			join	core.RefNbr#Raw()        r on  x.v1=r.Number and r.Type=k.AsnNbr
			join	whse.StockInOrder#Raw()  c on c.ID=r.MatterID

		)
		update cte set TotalSkuQty=NewTotalSkuQty;
		
		execute	whse.RcvSkuFee#Bill @orderIDs=@orderIDs;

		select	@result=(select count(*) from @spec); 

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END