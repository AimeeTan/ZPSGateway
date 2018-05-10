/*
@slip=    Comma[AsnNbr]
@result=  StockInOrderID
*/
--Smile
CREATE PROCEDURE [vmi].[StockInOrder$HubVerified](@slip tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;	

		declare	@daemon I32=0;

		declare	@actionID I32=(select CfmAsnHubVerified from core.Action#ID());

		declare	@spec core.TransitionSpec;
		insert	@spec 		
		select	t.* 
		from	loc.RefNbr#Slice(@slip)  x
		cross	apply core.RefNbr#Type() k
		join	core.RefNbr#Raw()        r on  x.Number=r.Number and r.Type=k.AsnNbr
		cross	apply core.Matter#Tobe(r.MatterID, @daemon, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@daemon, @beAffected=1;
	
END